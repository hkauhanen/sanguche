using Distributed

@everywhere cd(@__DIR__)

@everywhere function argfunc(args)
  return args
end

@everywhere dataset = argfunc($ARGS[1])
@everywhere fm_file = argfunc($ARGS[2])

@everywhere families = open(fm_file) do file
  readlines(file)
end


@everywhere using Pkg
@everywhere Pkg.activate("mrbayes_project")
@everywhere Pkg.instantiate()

##
@everywhere using ProgressMeter
@everywhere using CSV
@everywhere using DataFrames
@everywhere using Statistics
@everywhere using Distributions
@everywhere using Pipe
@everywhere using Dates
@everywhere using Random


try
  mkdir("../../$dataset/mrbayes/")
catch e
end

try
  mkdir("../../$dataset/mrbayes/logs/")
catch e
end

try
  mkdir("../../$dataset/mrbayes/converged/")
catch e
end


##

@everywhere using Conda
@everywhere Conda.pip_interop(true)
Conda.pip("install", "ete3")


@everywhere ENV["PYTHON"] = ""
Pkg.build("PyCall")
@everywhere using PyCall

@everywhere ete3 = pyimport("ete3")


##
@everywhere data = CSV.read("../../$dataset/data/charMtx.csv", DataFrame)

##
#@everywhere worldGlotF = download("https://osf.io/jyvgt/download", "../../$dataset/data/world_fullGlot.tre")
@everywhere worldGlotF = download("https://osf.io/download/jyvgt/", "../../$dataset/data/world_fullGlot.tre")

@everywhere glot = ete3.Tree(worldGlotF)

@everywhere glot.prune(data.longname)



# Remove families which have already converged.
@everywhere function rm_families_converged(fams; verbose = false)
  fams_to_remove = []

  for fm in fams
    if isfile("../../$dataset/mrbayes/converged/$fm.txt")
      push!(fams_to_remove, fm)
      if verbose
        println("Removed $fm as it has already converged in a previous analysis")
      end
    end
  end

  return fams[fams .∉ [fams_to_remove]]
end

@everywhere families = rm_families_converged(families)



##

@everywhere function mbScript(fm, ngen, append, nchains, temp)
  fmTaxa = filter(x -> x.glot_fam == fm, data).longname
  nex = """
#Nexus
\tBegin MrBayes;
\t\tset seed=6789580436154794230;
\t\tset swapseed = 614090213;
\t\texecute ../../$dataset/data/asjpNex/$fm.nex;
\t\tlset rates=gamma coding=all;
"""

  fmGlot = glot.copy()
  fmGlot.prune(fmTaxa)
  constraints = []
  if length(fmTaxa) > 5
    for nd in fmGlot.get_descendants()
      if !nd.is_leaf()
        push!(constraints, nd.get_leaf_names())
      end
    end
  end

  if length(constraints) > 0
    for (i, cn) in enumerate(constraints)
      nex *= "\t\tconstraint c$i = " * join(cn, " ") * ";\n"
    end

    nex *= "\t\tprset topologypr = constraints("
    nex *= join(["c$i" for i in 1:length(constraints)], ",") * ");\n"
  end

  nex *= """
\t\tprset brlenspr = clock:uniform;
\t\tprset clockvarpr = igr;
\t\tprset treeagepr=Gamma(0.05, 0.005);
\t\tprset shapepr=Exponential(10);
\t\tset beagleprecision=double;
\t\tmcmcp Burninfrac=0.5 stoprule=no stopval=0.01;
\t\tmcmcp filename=../../$dataset/data/asjpNex/output/$fm;
\t\tmcmcp samplefreq=1000 printfreq=5000 append=$append;
\t\tmcmc ngen=$ngen nchains=$nchains nruns=2 temp=$temp;
\t\tsump;
\t\tsumt;
\tend;
"""
  nex
end


if fm_file == "fm_problematic_wals.txt" || fm_file == "fm_problematic_grambank.txt"
  @everywhere mbScript(fm, ngen, append) = mbScript(fm, ngen, append, 8, 5.0)
else
  @everywhere mbScript(fm, ngen, append) = mbScript(fm, ngen, append, 4, 0.2)
end





##
@sync @distributed for fm in families
  println("Executing $fm")
  
  mbFile = "../../$dataset/mrbayes/$(fm).mb.nex"
  convFile = "../../$dataset/mrbayes/converged/$(fm).txt"
  logFile = "../../$dataset/mrbayes/logs/$(fm).csv"

  nrun = 1000000

  # If checkpointing file exists, we continue from there. Otherwise, start anew.
  open(mbFile, "w") do file
    write(file, mbScript(fm, nrun, "no"))
  end

  try
    if isfile("../../$dataset/data/asjpNex/output/$(fm).ckp")
      # set nrun to current number in checkpointing file, plus some
      open("../../$dataset/data/asjpNex/output/$(fm).ckp") do f
        ckplines = readlines(f)
        nrun = parse(Int, ckplines[3][14:(end-1)]) + nrun
      end
      open(mbFile, "w") do file
        write(file, mbScript(fm, nrun, "yes"))
      end
    end
  catch e
    println("ERROR: Checkpointing file probably empty... starting family from scratch!")
  end

  command = `mb $mbFile`

  run(command)

  function converged()
    pstat = CSV.read(
      "../../$dataset/data/asjpNex/output/$fm.pstat",
      DataFrame,
      header = 2,
      datarow = 3,
      delim = "\t",
      ignorerepeated = true,
    )

    maxPSRF = maximum(pstat.PSRF)

    tstat = CSV.read(
      "../../$dataset/data/asjpNex/output/$fm.tstat",
      DataFrame,
      header = 2,
      datarow = 3,
      delim = "\t",
      ignorerepeated = true,
    )

    meanStdev = mean(tstat[:,4])

    vstat = CSV.read(
      "../../$dataset/data/asjpNex/output/$fm.vstat",
      DataFrame,
      header = 2,
      datarow = 3,
      delim = "\t",
      ignorerepeated = true,
      missingstring="NA",
    ) |> dropmissing

    maxPSRF = maximum([maxPSRF, maximum(vstat.PSRF)])

    open(logFile, "a") do file
      date = Dates.now()
      write(file, "$fm,$date,$nrun,$meanStdev,$maxPSRF\n")
    end

    maxPSRF <= 1.1 && meanStdev <= 0.01
  end

  while !converged()
    nrun += 1000000

    open(mbFile, "w") do file
      write(file, mbScript(fm, nrun, "yes"))
    end

    try
      run(command)
    catch e
      println("ERROR: MrBayes exited with an error for whatever reason. Continuing...")
    end
  end

  if converged()
    open(convFile, "w") do file
      write(file, "Converged!")
    end
  end
end


