dataset = ARGS[1]
famsize = ARGS[2]
resource = ARGS[3]

nex_filesize_limit = 100_000


cd(@__DIR__)

using Pkg
Pkg.activate("mrbayes_project")
Pkg.instantiate()

##
using ProgressMeter
using CSV
using DataFrames
using Glob
using Statistics
using Distributions
using Pipe


try
  mkdir("mrbayes/")
catch e
end


try
  mkdir("mrbayes/converged/")
catch e
end



using Conda
Conda.pip_interop(true)
Conda.pip("install", "ete3")


ENV["PYTHON"] = ""
Pkg.build("PyCall")
using PyCall

ete3 = pyimport("ete3")


##
data = CSV.read("../data/charMtx.csv", DataFrame)

##
worldGlotF = download("https://osf.io/jyvgt/download", "../data/world_fullGlot.tre")

glot = ete3.Tree(worldGlotF)

glot.prune(data.longname)


##
all_families = open("../data/glot3.txt") do file
  readlines(file)
end


##### Chibchan will not converge for WALS, hence remove it
rm_family(fams, to_remove) = fams[fams .!= to_remove]
#
#if dataset == "wals"
#  all_families = rm_family(all_families, "Chibchan")
#end

all_families = rm_family(all_families, "Austronesian")



##### Remove families which have already converged.
function rm_families_converged(fams; verbose = false)
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



##### Remove either small or large families (i.e. we process the two groups
##### in different batches)
function rm_families_due_to_size(fams, limit, direction)
  newfams = []

  for fm in fams
    fs = filesize("../data/asjpNex/$fm.nex")
    if direction == "large"
      if fs > limit
        push!(newfams, fm)
      end
    elseif direction == "small"
      if fs <= limit
        push!(newfams, fm)
      end
    end
  end

  return newfams
end

all_families = rm_families_due_to_size(all_families, nex_filesize_limit, famsize)



##### DEBUG
#####println(length(families))


##### DEBUG
#=
for fm in families
println(fm)
end
=#




##

function mbScript_original(fm, ngen, append)
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
\t\tmcmc ngen=$ngen nchains=4 nruns=2;
\t\tsump;
\t\tsumt;
\tend;
"""
  nex
end


function mbScript_cpu(fm, ngen, append)
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

#\t\tset beagleprecision=double beaglescaling=dynamic beaglesse=yes;
  nex *= """
\t\tprset brlenspr = clock:uniform;
\t\tprset clockvarpr = igr;
\t\tprset treeagepr=Gamma(0.05, 0.005);
\t\tprset shapepr=Exponential(10);
\t\tset usebeagle=no;
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

function mbScript_gpu(fm, ngen, append, resourceid)
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
\t\tset usebeagle=yes beagleresource=$resourceid;
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

#=
if dataset == "wals"
  mbScript(x, y, z) = mbScript_cpu(x, y, z)
elseif dataset == "grambank"
  mbScript(x, y, z) = mbScript_gpu(x, y, z)
end
=#



##


if resource == "cpu"
  mbScript(x, y, z) = mbScript_cpu(x, y, z)
  nstep = 1_000_000
elseif resource == "gpu1"
  mbScript(x, y, z) = mbScript_gpu(x, y, z, "1")
  nstep = 1_000_000
elseif resource == "gpu2"
  mbScript(x, y, z) = mbScript_gpu(x, y, z, "2")
  nstep = 1_000_000
end


#=
if famsize == "large"
  nstep = 100_000
  max_generations = 100*nstep
elseif famsize == "small"
  nstep = 1_000_000
  max_generations = 50*nstep
end
=#


##### DEBUG: restrict to a couple of families
#####all_families = ["Ndu", "Tuu", "Uralic"]



# loop as long as there are non-converged families
while length(rm_families_converged(all_families)) > 0
#    global nrun += nstep

    local families = rm_families_converged(all_families)
    
    if length(families) == 0
      println("All families have converged!")
      break
    end

for fm in families

  ##### We try-catch this; in case a single family (or some families) exit with
  ##### an error for any reason, we don't want to be thrown out of the loop.
  try
    println("Executing $fm")
    
    mbFile = "mrbayes/$(fm).mb.nex"
    convFile = "mrbayes/converged/$(fm).txt"

    # If checkpointing file exists, we continue from there. Otherwise, start anew.
    if isfile("../data/asjpNex/output/$(fm).ckp")
      # set nrun to current number in checkpointing file
      open("../data/asjpNex/output/$(fm).ckp") do f
        ckplines = readlines(f)
        local nrun = parse(Int, ckplines[3][14:(end-1)]) + nstep
        open(mbFile, "w") do file
          write(file, mbScript(fm, nrun, "yes"))
        end
      end

    else
      open(mbFile, "w") do file
      write(file, mbScript(fm, nstep, "no"))
    end
    end

    if resource == "cpu"
      command = `mpirun -np 8 mb $mbFile`
    elseif resource == "gpu1" || resource == "gpu2"
      command = `mb $mbFile`
    end

    run(command)

    function converged()
      try
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
      if dataset == "nevermind" #dataset == "grambank" && fm == "Austronesian"
        return maxPSRF <= 1.2 && meanStdev <= 0.02
      else
        return maxPSRF <= 1.1 && meanStdev <= 0.01
      end
    catch e
      return false
    end
    end

    #=
    while !converged() && nrun < max_iterations
      nrun += 1000000
      open(mbFile, "w") do file
        write(file, mbScript(fm, nrun, "yes"))
      end
      run(command)
    end
    =#

    if converged()
      open(convFile, "w") do file
        write(file, "Converged!")
      end
    end
  catch e
    println(e)
  end
end
end
