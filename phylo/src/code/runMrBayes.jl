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


try
    mkdir("mrbayes/")
catch e
end



## this prepares, among other things, the 'families' variable
@everywhere include("prepMrBayes.jl")


##### Chibchan will not converge for WALS, hence remove it
if dataset == "wals"
    families = families[families .!= "Chibchan"]
end

##### DEBUG
println(length(families))


##
##### DEBUG: restrict to a couple of families
#####@everywhere families = ["Ndu", "Tuu", "Surmic"]
@sync @distributed for fm in families
  println("Executing $fm")
    mbFile = "mrbayes/$(fm).mb.nex"
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

        ##### employ slightly laxer convergence criteria:
        #maxPSRF <= 1.1 && meanStdev <= 0.01
        maxPSRF <= 1.2 && meanStdev <= 0.02
    end
    while !converged()
        nrun += 1000000
        open(mbFile, "w") do file
            write(file, mbScript(fm, nrun, "yes"))
        end
        run(command)
    end
end

