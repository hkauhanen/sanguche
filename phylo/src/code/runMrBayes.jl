using Distributed


# Workaround to pass command-line arguments to all worker processes; see
# https://discourse.julialang.org/t/how-to-pass-args-to-multiple-processes/80075/3
@everywhere myfunc(funcARGS) = funcARGS
@everywhere dataset = myfunc($ARGS)[1]


@everywhere cd(@__DIR__)

@everywhere using Pkg
@everywhere Pkg.activate("mrbayes_project")
@everywhere Pkg.instantiate()

##
@everywhere using ProgressMeter
@everywhere using CSV
@everywhere using DataFrames
@everywhere using Glob
@everywhere using Statistics
@everywhere using Distributions
@everywhere using Pipe


try
    mkdir("mrbayes/")
catch e
end


try
    mkdir("mrbayes/converged/")
catch e
end



@everywhere using Conda
@everywhere Conda.pip_interop(true)
#@everywhere Conda.pip("install", "ete3")
Conda.pip("install", "ete3")


@everywhere ENV["PYTHON"] = ""
@everywhere Pkg.build("PyCall")
@everywhere using PyCall

@everywhere ete3 = pyimport("ete3")


##
@everywhere data = CSV.read("../data/charMtx.csv", DataFrame)

##
@everywhere worldGlotF = download("https://osf.io/jyvgt/download", "../data/world_fullGlot.tre")

@everywhere glot = ete3.Tree(worldGlotF)

@everywhere glot.prune(data.longname)


##
@everywhere families = open("../data/glot3.txt") do file
    readlines(file)
end


##### Chibchan will not converge for WALS, hence remove it
@everywhere rm_family(fams, to_remove) = fams[fams .!= to_remove]

#@everywhere if dataset == "wals"
#  @everywhere families = rm_family(families, "Chibchan")
#end




##### Remove families which have already converged.
@everywhere function rm_families_converged(fams)
  fams_to_remove = []

  for fm in fams
    if isfile("mrbayes/converged/$fm.txt")
      push!(fams_to_remove, fm)
    end
  end

  return fams[fams .∉ [fams_to_remove]]
end

@everywhere families = rm_families_converged(families)


##### DEBUG
#####println(length(families))


##### DEBUG
#=
for fm in families
  println(fm)
end
=#




##

@everywhere function mbScript_cpu(fm, ngen, append)
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
\t\tset usebeagle=yes beagledevice=cpu;
\t\tset beagleprecision=double beaglescaling=dynamic beaglesse=yes;
\t\tmcmcp Burninfrac=0.5 stoprule=no stopval=0.01;
\t\tmcmcp filename=../data/asjpNex/output/$fm;
\t\tmcmcp samplefreq=1000 printfreq=5000 append=$append;
\t\tmcmc ngen=$ngen nchains=4 nruns=2;
\t\tsump;
\t\tsumt;
\tend;
"""
    nex
end

@everywhere function mbScript_gpu(fm, ngen, append)
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
\t\tset usebeagle=yes beagledevice=gpu;
\t\tset beagleprecision=single beaglescaling=dynamic;
\t\tmcmcp Burninfrac=0.5 stoprule=no stopval=0.01;
\t\tmcmcp filename=../data/asjpNex/output/$fm;
\t\tmcmcp samplefreq=1000 printfreq=5000 append=$append;
\t\tmcmc ngen=$ngen nchains=4 nruns=2;
\t\tsump;
\t\tsumt;
\tend;
"""
    nex
end


if dataset == "wals"
  @everywhere mbScript(x, y, z) = mbScript_cpu(x, y, z)
elseif dataset == "grambank"
  @everywhere mbScript(x, y, z) = mbScript_gpu(z, y, z)
end



@everywhere max_iterations = 100_000_000



##
##### DEBUG: restrict to a couple of families
#####@everywhere families = ["Ndu", "Tuu"]
@sync @distributed for fm in families
  println("Executing $fm")

  for old_output_file in glob("../data/asjpNex/output/$fm.*")
    rm(old_output_file)
  end

    mbFile = "mrbayes/$(fm).mb.nex"
    convFile = "mrbayes/converged/$(fm).txt"
    nrun = 1000000
    open(mbFile, "w") do file
        write(file, mbScript(fm, nrun, "no"))
    end
    ##### I've been unable to make things work in parallel. MPI process exits with errors
    ##### for some reason. Hence, we do this slowly but surely, in series...
    #####command = `mpirun -np 8 mb $mbFile`
    #command = `mpirun -np 1 mb $mbFile`
    command = `mb $mbFile`
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

        ##### employ slightly laxer convergence criteria for Austronesian for Grambank:
        if dataset == "grambank" && fm == "Austronesian"
          return maxPSRF <= 1.2 && meanStdev <= 0.02
        else
          return maxPSRF <= 1.1 && meanStdev <= 0.01
        end
    end
    while !converged() && nrun < max_iterations
        nrun += 1000000
        open(mbFile, "w") do file
            write(file, mbScript(fm, nrun, "yes"))
        end
        run(command)
    end

    if converged()
      open(convFile, "w") do file
        write(file, "Converged!")
      end
    end
end

