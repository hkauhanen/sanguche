# Creates the file ../tmp/wals/data.jls
#
# adapted from:
# https://github.com/gerhardJaeger/phylogeneticTypology/blob/main/code/createData.jl
# 
# MIT License


using CSV
using DataFrames
using Pipe
using Serialization


include("params.jl")

features = features_wals


try
  mkdir("../tmp")
catch e
end

try
  mkdir("../tmp/wals")
catch e
end


languagesF = "../tmp/wals/languages.csv"
valsF = "../tmp/wals/values.csv"
paramsF = "../tmp/wals/parameters.csv"
codesF = "../tmp/wals/codes.csv"


!(isfile(languagesF) && isfile(valsF) && isfile(paramsF)) && begin
  wals2020 = download(
                      "https://github.com/cldf-datasets/wals/archive/v2020.zip",
                      "../tmp/wals2020.zip",
                     )
  run(`unzip $wals2020 -d ../tmp/`)
  cp("../tmp/wals-2020/cldf/languages.csv", languagesF, force = true)
  cp("../tmp/wals-2020/cldf/values.csv", valsF, force = true)
  cp("../tmp/wals-2020/cldf/parameters.csv", paramsF, force = true)
  cp("../tmp/wals-2020/cldf/codes.csv", codesF, force = true)
end


languages = CSV.read(languagesF, DataFrame)

vals = CSV.read(valsF, DataFrame)

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##


data = unstack(
               (@pipe vals |>
                filter(x -> x.Parameter_ID ∈ features, _) |>
                select(_, [:Language_ID, :Parameter_ID, :Value])),
               :Language_ID,
               :Parameter_ID,
               :Value,
              )

##

filter!(x -> x.Parameter_ID ∈ features, codes)

select!(codes, [:ID, :Parameter_ID, :Name, :Number])

filter!(x -> x.Number ∈ [1,2], codes)
##


for i in 1:size(data,1), j in 2:size(data,2)
  v = data[i,j]
  if !ismissing(v) && v > 2
    data[i,j] = missing
  end
end


##
nValues = vec(length(features) .- mapslices(x -> sum(ismissing.(x)), Array(data), dims=2))
insertcols!(data, 2, :nValues => nValues)

sort!(data, :nValues, rev=true)

##

dropmissing!(languages, :Glottocode)

data = innerjoin(
                 data,
                 select(languages, [:ID, :Glottocode, :Family]),
                 on = :Language_ID => :ID,
                )

unique!(data, :Glottocode)

filter!(x -> x.nValues >= 5, data)


serialize("../tmp/wals/data.jls", data)

