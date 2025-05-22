include("deps.jl")

using Distributed


@everywhere using Pkg
@everywhere Pkg.activate("Sanguche")
#@everywhere Pkg.instantiate()


# all processors need access to the following
@everywhere using CSV
@everywhere using DataFrames
@everywhere using FreqTables
@everywhere using Random
@everywhere using Serialization
@everywhere using Statistics


# for a mysterious reason, we need to do the following to pass the 
# command-line argument to all worker processes; cf.
# https://discourse.julialang.org/t/how-to-pass-args-to-multiple-processes/80075/3
@everywhere myargfunc(x) = x
@everywhere dataset = myargfunc($ARGS)[1]
@everywhere limtype = myargfunc($ARGS)[2]


@everywhere cd("../../$dataset")


@everywhere results = deserialize("./dicts/grid.jls")
@everywhere Ddata = deserialize("./dicts/Ddata.jls")
@everywhere Ddists = deserialize("./dicts/Ddists.jls")



try
    mkdir("../results")
catch e
end


try
    mkdir("../results/$dataset")
catch e
end



# count number of times each element of 'x' occurs in 'y'
@everywhere function levelcounter(x, y)
    out = Dict{Any,Int}()

    for elx in x
        out[elx] = 0
    end

    for elx in x
        for ely in y
            if ely == elx
                out[elx] = out[elx] + 1
            end
        end
    end

    out
end


# compute neighbourhood entropy for types in 'typeset'
@everywhere function NE(typeset, data, dists)
    # cycle through types
    # languages in typeset
    datat = subset(data, :type => (t -> t .∈ [typeset]))

    # their neighbours
    neighbours = subset(dists, :language_ID => (a -> a .∈ [datat.Language_ID])).neighbour_ID

    if length(neighbours) == 0
        println("WARNING: empty neighbourhood (this shouldn't happen)")
    end

    # those neighbours' data
    datan = subset(data, :Language_ID => (a -> a .∈ [neighbours]))

    # counts of different types among those neighbours
    cnts = levelcounter(["11", "12", "21", "22"], datan.type)

    # total number of neighbours
    total = sum(values(cnts))

    # entropy
    entropy = 0
    for k in keys(cnts)
        if cnts[k] > 0
            entropy = entropy - (cnts[k]/total)*log2(cnts[k]/total)
        end
    end

    return entropy
end


# computes the various "sandwichness" metrics
@everywhere function sandwichness(r, results, Ddata, Ddists; limtype = "km")
    #resultsh = subset(results, :pair => (p -> p .== r.pair))
    datah = Ddata[r.pair]
    distsh = Ddists[r.pair]

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
    pref_types = []
    dispref_types = []
    for type in types
        #if resultsh[1, "pref"*type] == 0
        if r["pref"*type] == 1
            push!(pref_types, type)
        end
        if r["dispref"*type] == 1
            push!(dispref_types, type)
        end
    end

    out.H .= NE(types, datah, distsh)
    out.H_pref .= length(pref_types) == 0 ? missing : NE(pref_types, datah, distsh)
    out.H_dispref .= length(dispref_types) == 0 ? missing : NE(dispref_types, datah, distsh)
    out.N .= nrow(datah)
    out.mean_distance .= mean(distsh.distance)
    out.sd_distance .= std(distsh.distance)

    out.mean_nsize .= nrow(distsh)/nrow(datah)

    return out
end


sand = @distributed (vcat) for r in eachrow(results)
    out = DataFrame(r)
    out = out[:, Between(:pair, :class)]
    out.degree .= r.degree

    geo_results = sandwichness(r, results, Ddata, Ddists; limtype=limtype)
    innerjoin(out, geo_results, on=:pair)
end



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
serialize("../results/$dataset/sand_results.jls", merged)
CSV.write("../results/$dataset/sand_results.csv", merged)

