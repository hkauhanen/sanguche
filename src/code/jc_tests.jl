include("deps.jl")

using Distributed
using ProgressMeter


@everywhere using Pkg
@everywhere Pkg.activate("Sanguche")
#@everywhere Pkg.instantiate()

@everywhere include("permutation_params.jl")


# all processors need access to the following
@everywhere using CSV
@everywhere using DataFrames
@everywhere using FreqTables
@everywhere using Random
@everywhere using Serialization
@everywhere using Statistics
@everywhere using Pipe


# for a mysterious reason, we need to do the following to pass the 
# command-line argument to all worker processes; cf.
# https://discourse.julialang.org/t/how-to-pass-args-to-multiple-processes/80075/3
@everywhere myargfunc(x) = x


@everywhere LBFLEVEL = 4.0


@everywhere jawa = CSV.read("../../results/gbwals_all_pairs.csv", DataFrame)
transform!(jawa, [:feat1, :feat2] => ByRow(((a,b) -> "$a-$b")) => :fpair)
transform!(jawa, :fpair => (fp -> Set.(split.(fp, "-"))) => :pair_ID)


metaout = Dict{String,DataFrame}()


for dataset in ["WALS", "Grambank"]
    @everywhere results = deserialize("../../longresults/$dataset/sand_results.jls")
    @everywhere grid = deserialize("../../$dataset/dicts/grid.jls")

    frame = allcombinations(DataFrame, 
                            pair = unique(results["empirical"].pair),
                            type = ["11", "12", "21", "22"],
                            degree = unique(results["empirical"].degree),
                            gravity_exponent = [2.0],
                            combination = ["AND", "OR", "XOR"],
                            nullhypothesis = ["global", "family"])

    out = @distributed (vcat) for r in eachrow(frame)
        ghere = subset(grid, :pair => (p -> p .== r.pair))

        if ghere[!, "pref$(r.type)"][1] == 1
            attestation = "overattested"
        elseif ghere[!, "dispref$(r.type)"][1] == 1
            attestation = "underattested"
        else
            attestation = "neither"
        end

        jawahere = subset(jawa, :pair_ID => (pid -> pid .== Set.(split.(r.pair, " & "))))
        jagdataset = dataset == "Grambank" ? "GramBank" : dataset
        jawahere = subset(jawahere, :dataset => (d -> d .== jagdataset))

        status = "unknown"

        if nrow(jawahere) > 0 && jawahere.lbf[1] >= LBFLEVEL
            status = "interacting"
        end

        pedigree = "other"

        if status == "interacting" && attestation == "underattested"
            pedigree = "dispreferred"
        elseif ghere.class[1] == "control" && attestation == "underattested"
            pedigree = "control underattested"
        end

        df = DataFrame(dataset = dataset, pair = r.pair, f1 = split(r.pair, " & ")[1], f2 = split(r.pair, " & ")[2], class = ghere.class, type = r.type, attestation = attestation, status = status, pedigree = pedigree, frequency = ghere[!, "freq$(r.type)"], degree = r.degree, gravity_exponent = r.gravity_exponent, combination = r.combination, nullhypothesis = r.nullhypothesis)

        rhere = subset(results["empirical"], [:pair, :degree] => ((p,d) -> p .== r.pair .&& d .== r.degree))

        rand_joins = [subset(results["rand_$(r.nullhypothesis)"][i], [:pair, :degree] => ((p,d) -> p .== r.pair .&& d .== r.degree))[!, "JC_$(r.type)_$(r.combination)_GREX$(r.gravity_exponent)_$(r.nullhypothesis)"][1] for i in keys(results["rand_$(r.nullhypothesis)"])]

        df.joincount .= rhere[!, "JC_$(r.type)_$(r.combination)_GREX$(r.gravity_exponent)_none"]

        df.zscore .= (df.joincount .- Statistics.mean(rand_joins)) ./ Statistics.std(rand_joins)

        df.pval_less .= sum(rand_joins .<= df.joincount) / length(rand_joins)
        df.pval_more .= sum(rand_joins .>= df.joincount) / length(rand_joins)

        df
    end

    metaout[dataset] = out
end



# writeout
CSV.write("../../results/joincounts_all.csv", vcat(metaout["WALS"], metaout["Grambank"]))



