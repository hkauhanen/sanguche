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
@everywhere dataset = myargfunc($ARGS)[1]
@everywhere limtype = myargfunc($ARGS)[2]


@everywhere results = deserialize("../../$dataset/dicts/grid.jls")
@everywhere Ddata = deserialize("../../$dataset/dicts/Ddata.jls")
@everywhere Ddists = deserialize("../../$dataset/dicts/Ddists.jls")


try
    mkdir("../../results")
catch e
end


try
    mkdir("../../results/$dataset")
catch e
end


try
    mkdir("../../longresults")
catch e
end


try
    mkdir("../../longresults/$dataset")
catch e
end



# join count statistic: neighbours of languages of type in 'focal' of type in 'target'
@everywhere function JCgravity(focal, target, data, dists; exponent = 2.0)
    datat = subset(data, :type => (t -> t .∈ [focal]))

    out = 0.0

    for lang in unique(datat.Language_ID)
        neighbours = subset(dists, :language_ID => (a -> a .== lang)).neighbour_ID

        datan = subset(data, :Language_ID => (a -> a .∈ [neighbours]))

        target_neighbours = subset(datan, :type => (t -> t .∈ [target])).Language_ID

        df = subset(dists, :language_ID => (a -> a .== lang))
        df = subset(df, :neighbour_ID => (a -> a .∈ [target_neighbours]))
        df = subset(df, :distance => (d -> d .!= 0.0))

        out += sum(df.distance .^ -exponent)
    end

    #=
    if focal == target
    out = out / 2
    end
    =#

    return out / length(unique(datat.Language_ID))
end


@everywhere function JCgravity_INCORRECT(focal, target, data, dists; exponent = 2.0)
    datat = subset(data, :type => (t -> t .∈ [focal]))

    neighbours = subset(dists, :language_ID => (a -> a .∈ [datat.Language_ID])).neighbour_ID

    datan = subset(data, :Language_ID => (a -> a .∈ [neighbours]))

    target_neighbours = subset(datan, :type => (t -> t .∈ [target])).Language_ID

    df = subset(dists, :language_ID => (a -> a .∈ [datat.Language_ID]))
    df = subset(df, :neighbour_ID => (a -> a .∈ [target_neighbours]))
    df = subset(df, :distance => (d -> d .!= 0.0))

    out = sum(df.distance .^ -exponent)

    if focal == target
        out = out / 2
    end

    return out
end


# computes the various "sandwichness" metrics
@everywhere function sandwichness(r, results, Ddata, Ddists; limtype = "km", randomize = "none")
    #resultsh = subset(results, :pair => (p -> p .== r.pair))
    datah = deepcopy(Ddata[r.pair])
    distsh = Ddists[r.pair]

    # add "LargeFamily" (i.e. pool small families together so that family-based
    # randomization makes sense
    familysizes = @pipe datah |> groupby(_, :Family) |> combine(_, nrow => :size)
    smolfamilies = subset(familysizes, :size => (s -> s .<= SIZELIMIT)).Family

    function myfamilyfunction(f)
        if f in smolfamilies
            return "OTHER"
        else
            return f
        end
    end

    transform!(datah, :Family => (f -> myfamilyfunction.(f)) => :LargeFamily)

    degree = r.degree

    if limtype == "km"
        distsh = subset(distsh, :distance => (i -> i .<= degree))
    elseif limtype == "rank"
        distsh = subset(distsh, :eachindex => (i -> i .<= degree))
    else
        println("invalid limtype!")
    end

    out = DataFrame(pair=r.pair)

    types = ["11", "12", "21", "22"]

    # IMPORTANT! "pref" and "dispref" here have the meanings of "overattested"
    # and "underattested", respectively, NOT "preferred" and "dispreferred".
    pref_types = []
    dispref_types = []
    for type in types
        if r["pref"*type] == 1
            push!(pref_types, type)
        end
        if r["dispref"*type] == 1
            push!(dispref_types, type)
        end
    end

    fun = JCgravity

    for expon in [2.0]#[0.0, 1.0, 2.0]
        for focal in types
            # feature value level joins
            f1 = focal[1]
            f2 = focal[2]

            #for comparison in ["f1", "f2", "AND", "OR", "XOR"]
            for comparison in ["AND", "OR", "XOR"]
                f1joins = ["$(f1)1", "$(f1)2"]
                f2joins = ["1$(f2)", "2$(f2)"]

                if comparison == "f1"
                    leveljoins = f1joins
                elseif comparison == "f2"
                    leveljoins = f2joins
                elseif comparison == "AND"
                    leveljoins = intersect(f1joins, f2joins)
                elseif comparison == "OR"
                    leveljoins = union(f1joins, f2joins)
                elseif comparison == "XOR"
                    leveljoins = setdiff(union(f1joins, f2joins), intersect(f1joins, f2joins))
                end

                #world-wide randomization
                if randomize == "global"
                    Random.shuffle!(datah.type)
                elseif randomize == "family"
                    #family-wide randomization
                    @pipe datah |> groupby(_, :LargeFamily) |> transform!(_, :type => Random.shuffle => :type)
                end

                JC = fun([focal], leveljoins, datah, distsh; exponent = expon)
                out[!, "JC_$(focal)_$(comparison)_GREX$(expon)_$(randomize)"] .= JC
            end
        end
    end

    out.N .= nrow(datah)
    out.mean_distance .= mean(distsh.distance)
    out.sd_distance .= std(distsh.distance)

    out.mean_nsize .= nrow(distsh)/nrow(datah)

    out.randomize .= randomize

    return out
end

println("\nEmpirical.")

sand = @showprogress dt=1 desc="Computing empirical..." @distributed (vcat) for r in eachrow(results)
    out = DataFrame(r)
    out = out[:, Between(:pair, :class)]
    out.degree .= r.degree

    geo_results = sandwichness(r, results, Ddata, Ddists; limtype=limtype)
    innerjoin(out, geo_results, on=:pair)
end

NREPS = 200

rand_global = Dict{Int,DataFrame}()

println("\nGlobal randomization.")

@showprogress dt=1 desc="Computing global randomization..." for rep in 1:NREPS
    local sand = @distributed (vcat) for r in eachrow(results)
        out = DataFrame(r)
        out = out[:, Between(:pair, :class)]
        out.degree .= r.degree

        geo_results = sandwichness(r, results, Ddata, Ddists; limtype=limtype, randomize = "global")
        innerjoin(out, geo_results, on=:pair)
    end

    sand.rep .= rep
    rand_global[rep] = sand
end

rand_family = Dict{Int,DataFrame}()

println("\nFamily-based randomization.")

@showprogress dt=1 desc="Computing family-based randomization..." for rep in 1:NREPS
    local sand = @distributed (vcat) for r in eachrow(results)
        out = DataFrame(r)
        out = out[:, Between(:pair, :class)]
        out.degree .= r.degree

        geo_results = sandwichness(r, results, Ddata, Ddists; limtype=limtype, randomize = "family")
        innerjoin(out, geo_results, on=:pair)
    end

    sand.rep .= rep
    rand_family[rep] = sand
end


results = Dict("empirical" => sand,
               "rand_global" => rand_global,
               "rand_family" => rand_family)

serialize("../../longresults/$dataset/sand_results.jls", results)


println("\nAll done! Results to be found in longresults/$dataset.")


#=

# finally, we figure out the summary statistics we're interested in

types = ["11", "12", "21", "22"]

merged = innerjoin(results, sand, on=[:pair, :degree], makeunique=true)


# select only wanted columns
select!(merged, Not(:f1_1, :f2_1, :class_1))


# make a pair identifier which is a Set of the two features; this way, order
# of features does not matter
stringtonumber(s) = Set(split(s, " & "))

transform!(merged, :pair => (p -> stringtonumber.(p)) => :pair_ID)


# serialize results to file, and to a CSV also (why not)
#serialize("../results/$dataset/sand_results.jls", merged)
#CSV.write("../results/$dataset/sand_results.csv", merged)

=#
