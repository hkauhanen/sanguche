dataset = ARGS[1]

using Distributed

@everywhere cd(@__DIR__)

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
  mkdir("mrbayes/")
catch e
end

try
  mkdir("mrbayes/logs/")
catch e
end

try
  mkdir("mrbayes/converged/")
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
@everywhere data = CSV.read("../data/charMtx.csv", DataFrame)

##
@everywhere worldGlotF = download("https://osf.io/jyvgt/download", "../data/world_fullGlot.tre")

@everywhere glot = ete3.Tree(worldGlotF)

@everywhere glot.prune(data.longname)


##
@everywhere families_tmp = open("../data/glot3.txt") do file
  readlines(file)
end



# Remove families which have already converged.
@everywhere function rm_families_converged(fams; verbose = false)
  fams_to_remove = []

  for fm in fams
    if isfile("mrbayes/converged/$fm.txt")
      push!(fams_to_remove, fm)
      if verbose
        println("Removed $fm as it has already converged in a previous analysis")
      end
    end
  end

  return fams[fams .∉ [fams_to_remove]]
end

@everywhere families_tmp2 = rm_families_converged(families_tmp)



# We want to sort the families so that large and small families are being processed concurrently;
# this leads to the most efficient use of wall-clock time. To do this, we take one family from
# the top of the pile, the next from the bottom, the next from the top, the next from the bottom...
# and so on. Kind of like the first round on the Vierschanzentournee.
@everywhere df = DataFrame(fm=families_tmp2)
@everywhere transform!(df, :fm => (f -> "../data/asjpNex/" .* f .* ".nex") => :filename)
@everywhere transform!(df, :filename => (f -> filesize.(f)) => :filesize)
@everywhere sort!(df, :filesize, rev=true)
@everywhere df.sizeorder = 1:nrow(df)
@everywhere df.neworder = (df.sizeorder .- nrow(df)/2) .^ 2
@everywhere sort!(df, :neworder, rev=true)
@everywhere families = df.fm



@everywhere families = ["Chibchan", "Siouan"]



##

@everywhere function mbScript(fm, ngen, append; nchains = 8, temp = 2.0)
  fmTaxa = filter(x -> x.glot_fam == fm, data).longname
  nex = """
#Nexus
\tBegin MrBayes;
\t\tset seed=6789580436154794230;
\t\tset swapseed = 614090213;
\t\texecute ../data/asjpNex/$fm.nex;
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
\t\tmcmcp filename=../data/asjpNex/output/$fm;
\t\tmcmcp samplefreq=1000 printfreq=5000 append=$append;
\t\tmcmc ngen=$ngen nchains=$nchains nruns=2 temp=$temp;
\t\tsump;
\t\tsumt;
\tend;
"""
  nex
end





##### Chibchan will not converge for WALS, hence remove it
#if dataset == "wals"
#    families = families[families .!= "Chibchan"]
#end



##
@sync @distributed for fm in families
  println("Executing $fm")
  
  mbFile = "mrbayes/$(fm).mb.nex"
  convFile = "mrbayes/converged/$(fm).txt"
  logFile = "mrbayes/logs/$(fm).csv"

  nrun = 1000000

  # If checkpointing file exists, we continue from there. Otherwise, start anew.
  try
    if isfile("../data/asjpNex/output/$(fm).ckp")
      # set nrun to current number in checkpointing file, plus some
      open("../data/asjpNex/output/$(fm).ckp") do f
        ckplines = readlines(f)
        nrun = parse(Int, ckplines[3][14:(end-1)]) + nrun
      end
      open(mbFile, "w") do file
        write(file, mbScript(fm, nrun, "yes"))
      end
    end
  catch e
    println("ERROR: Checkpointing file probably empty... continuing")
    open(mbFile, "w") do file
      write(file, mbScript(fm, nrun, "no"))
    end
  end


  command = `mpirun -np 8 mb $mbFile`
  #command = `mb $mbFile`
  run(command)

  function converged()
    pstat = CSV.read(
      "../data/asjpNex/output/$fm.pstat",
      DataFrame,
      header = 2,
      datarow = 3,
      delim = "\t",
      ignorerepeated = true,
    )

    maxPSRF = maximum(pstat.PSRF)

    tstat = CSV.read(
      "../data/asjpNex/output/$fm.tstat",
      DataFrame,
      header = 2,
      datarow = 3,
      delim = "\t",
      ignorerepeated = true,
    )

    meanStdev = mean(tstat[:,4])

    vstat = CSV.read(
      "../data/asjpNex/output/$fm.vstat",
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


