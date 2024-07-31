# Creates the file ../tmp/grambank/data.jls
#
# adapted from:
# https://github.com/gerhardJaeger/phylogeneticTypology/blob/main/code/createData.jl
# 
# MIT License


using CSV
using DataFrames
using Pipe
using Serialization


include("features_grambank.jl")


try
  mkdir("../tmp")
catch e
end

try
  mkdir("../tmp/grambank")
catch e
end


languagesF = "../tmp/grambank/languages.csv"
valsF = "../tmp/grambank/values.csv"
paramsF = "../tmp/grambank/parameters.csv"
codesF = "../tmp/grambank/codes.csv"


!(isfile(languagesF) && isfile(valsF) && isfile(paramsF)) && begin
  gb = download(
                "https://zenodo.org/records/7844558/files/grambank/grambank-v1.0.3.zip?download=1",
                "../tmp/grambank-v1.0.3.zip",
               )
  run(`unzip $gb -d ../tmp/`)
  gbdir = "grambank-grambank-7ae000c"
  cp("../tmp/$gbdir/cldf/languages.csv", languagesF, force = true)
  cp("../tmp/$gbdir/cldf/values.csv", valsF, force = true)
  cp("../tmp/$gbdir/cldf/parameters.csv", paramsF, force = true)
  cp("../tmp/$gbdir/cldf/codes.csv", codesF, force = true)
end


languages = CSV.read(languagesF, DataFrame)

vals = CSV.read(valsF, DataFrame)

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##


data = unstack(
               (@pipe vals |>
                filter(x -> x.Parameter_ID ∈ features_original, _) |>
                select(_, [:Language_ID, :Parameter_ID, :Value])),
               :Language_ID,
               :Parameter_ID,
               :Value,
              )

##

filter!(x -> x.Parameter_ID ∈ features_original, codes)




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



# construct NRc and PN
# 
function feature_filter(a,b)
  if ismissing(a) || ismissing(b)
    return missing
  else
    if a == "1" && b == "2"
      return "1"
    elseif a == "2" && b == "1"
      return "2"
    else
      return missing
    end
  end
end

# Construct VO
#
# Logic:
#
# OV = (133:1 & 130:1) | (132:1 & 130:2)
# VO = (131:1 & 130:2) | (132:1 & 130:1)
#
function VO_filter(gb130, gb131, gb132, gb133)
  if ismissing(gb130) || ismissing(gb131) || ismissing(gb132) || ismissing(gb133)
    return missing
  else
    if (gb133 == "2" && gb130 == "1") || (gb132 == "2" && gb130 == "2")
      return "1"
    elseif (gb131 == "2" && gb130 == "2") || (gb132 == "2" && gb130 == "1")
      return "2"
    else
	    return missing
    end
  end
end

#transform!(data, [:GB131, :GB133] => ((a,b) -> feature_filter.(a,b)) => :VO)
transform!(data, [:GB130, :GB131, :GB132, :GB133] => ((a,b,c,d) -> VO_filter.(a,b,c,d)) => :VO)

transform!(data, [:GB327, :GB328] => ((a,b) -> feature_filter.(a,b)) => :NRc)
transform!(data, [:GB074, :GB075] => ((a,b) -> feature_filter.(a,b)) => :PN)


##
nValues = vec(length(features_original) .- mapslices(x -> sum(ismissing.(x)), Array(data), dims=2))
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


