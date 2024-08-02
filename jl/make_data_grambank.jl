# Creates the file ../tmp/grambank/data.jls
#
# To be run after extend_grambank.jl has been run!
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

features = features_grambank


languagesF = "../tmp/grambank/languages.csv"
valsF = "../tmp/grambank/values-ext.csv"
codesF = "../tmp/grambank/codes-ext.csv"


languages = CSV.read(languagesF, DataFrame)

vals = CSV.read(valsF, DataFrame)

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




select!(codes, [:ID, :Parameter_ID, :Name])

#filter!(x -> x.Name ∈ [1,2], codes)
##


# some GB values are "?"; replace these with missing
for i in 1:size(data,1), j in 2:size(data,2)
  if !ismissing(data[i,j]) && data[i,j] == "?"
    data[i,j] = missing
  end
end

# for some GB features, coding starts at 0. If so, increase all values by one
for feat in names(data)[2:end]
  if minimum(subset(codes, :Parameter_ID => p -> p .== feat).Name) == 0
    for r in 1:nrow(data)
      if !ismissing(data[r, feat]) && data[r, feat] == "0"
        data[r, feat] = "1"
      elseif !ismissing(data[r, feat]) && data[r, feat] == "1"
        data[r, feat] = "2"
      elseif !ismissing(data[r, feat]) && data[r, feat] == "2"
        data[r, feat] = "3"
      elseif !ismissing(data[r, feat]) && data[r, feat] == "3"
        data[r, feat] = "4"
      end
    end
  end
end

#filter!(x -> x.Name ∈ [1,2], codes)



for i in 1:size(data,1), j in 2:size(data,2)
  v = data[i,j]
  if !ismissing(v) && isnothing(tryparse(Int, v))
    data[i,j] = missing
  elseif !ismissing(v) && parse(Int, v) > 2
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
                 select(languages, [:ID, :Glottocode]),
                 on = :Language_ID => :ID,
                )

unique!(data, :Glottocode)

filter!(x -> x.nValues >= 5, data)


serialize("../tmp/grambank/data.jls", data)


