cd(@__DIR__)

include("features_wals.jl")
include("params.jl")

using Pkg
Pkg.activate("JW")
#Pkg.instantiate()

##
using CSV
using DataFrames
using Pipe
using DataStructures
using Serialization
using StatsBase
using ProgressMeter
using Random
Random.seed!(2002261988307380348)

##

try
    mkdir("../../wals")
catch e
end

cd("../../wals")

try
    mkdir("./data")
catch e
end

try
    mkdir("./data/database")
catch e
end



languagesF = "./data/database/languages.csv"
valsF = "./data/database/values.csv"
paramsF = "./data/database/parameters.csv"
codesF = "./data/database/codes.csv"
dataF = "./data/database/data_preprocessed.csv"


!(isfile(languagesF) && isfile(valsF) && isfile(paramsF)) && begin
    try
        mkdir("tmp")
    catch e
    end

    wals2020 = download(
                        "https://github.com/cldf-datasets/wals/archive/v2020.zip",
                        "tmp/wals2020.zip",
                       )
    run(`unzip $wals2020 -d tmp/`)
    cp("tmp/wals-2020/cldf/languages.csv", languagesF, force = true)
    cp("tmp/wals-2020/cldf/values.csv", valsF, force = true)
    cp("tmp/wals-2020/cldf/parameters.csv", paramsF, force = true)
    cp("tmp/wals-2020/cldf/codes.csv", codesF, force = true)
    rm("tmp", recursive = true)
end


##

languages = CSV.read(languagesF, DataFrame)

vals = CSV.read(valsF, DataFrame)

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##

woFeatures = features

neededFeatures = features_pre_preprocessing

data = unstack(
               (@pipe vals |>
                filter(x -> x.Parameter_ID ∈ neededFeatures, _) |>
                select(_, [:Language_ID, :Parameter_ID, :Value])),
               :Language_ID,
               :Parameter_ID,
               :Value,
              )


# filter used to construct PolQ
#
function feature_filter_PolQ(a)
    if ismissing(a)
        return missing
    else
        if a == 1 || a == 3
            return 1
        else
            return 2
        end
    end
end


# filter used to construct NegM
#
function feature_filter_NegM(a)
    if ismissing(a)
        return missing
    else
        if a == 1 || a == 5
            return 1
        elseif a == 6
            return missing
        else
            return 2
        end
    end
end


# do the transforms
#
if "112A" in neededFeatures
    transform!(data, "112A" => (a -> feature_filter_NegM.(a)) => "NegM")
    select!(data, Not("112A"))
end
if "116A" in neededFeatures
    transform!(data, "116A" => (a -> feature_filter_PolQ.(a)) => "PolQ")
    select!(data, Not("116A"))
end


# add our new features to the values table
#
#=
dd = stack(data[:, [:Language_ID, :PolQ, :NegM]], [:PolQ, :NegM])
rename!(dd, [:Language_ID, :Parameter_ID, :Value])
transform!(dd, [:Language_ID, :Parameter_ID] => ((a,b) -> b .* "-" .* a) => :ID)
transform!(dd, [:Value, :Parameter_ID] => ((a,b) -> b .* "-" .* string(a)) => :Code_ID)
select!(dd, [:ID, :Language_ID, :Parameter_ID, :Value, :Code_ID])
dd[!, :Comment] .= "Reconstructed from other features"
dd[!, :Source] .= "the authors"
dd[!, :Example_ID] .= missing
vals = [vals; dd] 
=#


# also need to add information about new features into codes table
#
push!(codes, ["PolQ-0", "PolQ", "no polar question particle", "no polar question particle", 0, ""])
push!(codes, ["PolQ-1", "PolQ", "polar question particle", "polar question particle", 1, ""])
push!(codes, ["NegM-0", "NegM", "no negative affixes", "no negative affixes", 0, ""])
push!(codes, ["NegM-1", "NegM", "negative affixes", "negative affixes", 1, ""])


# writeout
#
#CSV.write(valsF, vals)
CSV.write(codesF, codes)
CSV.write(dataF, data)



