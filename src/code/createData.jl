cd(@__DIR__)

dataset = ARGS[1]

include("features_$dataset.jl")
include("params.jl")

using Pkg
Pkg.activate("JW")
Pkg.instantiate()

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


cd("../../$dataset")


languagesF = "./data/database/languages.csv"
valsF = "./data/database/values.csv"
paramsF = "./data/database/parameters.csv"
codesF = "./data/database/codes.csv"
datainF = "./data/database/data_preprocessed.csv"
dataoutF = "./data/data.csv"


##

languages = CSV.read(languagesF, DataFrame)

#vals = CSV.read(valsF, DataFrame)

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##


woFeatures = features


data = CSV.read(datainF, DataFrame)


##
#
## 'codes' is not used in the code that follows, so we may as well
## comment out these lines

#filter!(x -> x.Parameter_ID ∈ woFeatures, codes)

#select!(codes, [:ID, :Parameter_ID, :Name, :Number])

#filter!(x -> x.Number ∈ [1,2], codes)
##

for i in 1:size(data,1), j in 2:size(data,2)
    v = data[i,j]
    if !ismissing(v) && v > 2
        data[i,j] = missing
    end
end


##
nValues = vec(length(woFeatures) .- mapslices(x -> sum(ismissing.(x)), Array(data), dims=2))
insertcols!(data, 10 + (length(woFeatures) - 8), :nValues => nValues)
#insertcols!(data, 1, :nValues => nValues)

sort!(data, :nValues, rev=true)

##

dropmissing!(languages, :Glottocode)

data = innerjoin(
    data,
    select(languages, [:ID, :Glottocode]),
    on = :Language_ID => :ID,
)

unique!(data, :Glottocode)

filter!(x -> x.nValues >= 6, data)


if dataset == "wals"
    fDict = Dict(fPairs)
end

rename!(data, fDict)


CSV.write(dataoutF, data)



