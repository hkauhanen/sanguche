# This script downloads Grambank and adds features VO, PN and NRc, 
# which are absent as single features in Grambank but can be reconstructed 
# from pairs of features
#
# Parts of the script adapted from:
# https://github.com/gerhardJaeger/phylogeneticTypology/blob/main/code/createData.jl
# 
# MIT License


include("deps.jl")


using CSV
using DataFrames
using Pipe
using Serialization


include("params.jl")

features = features_grambank


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


#subset!(vals, :Parameter_ID => (p -> p .∈ [["GB030", "GB302", "GB130", "GB131", "GB132", "GB133", "GB074", "GB075", "GB065", "GB193", "GB025", "GB024", "GB327", "GB328"]]))

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##


features_original = features
append!(features_original, ["GB130", "GB131", "GB132", "GB133", "GB074", "GB075", "GB327", "GB328", "GB193"])


data = unstack(
               (@pipe vals |>
                filter(x -> x.Parameter_ID ∈ features_original, _) |>
                select(_, [:Language_ID, :Parameter_ID, :Value])),
               :Language_ID,
               :Parameter_ID,
               :Value,
              )

##


# binarize GB193 properly
#
function NA_filter(a)
  if ismissing(a)
    return missing
  else
    if a == "1"
      return "0"
    elseif a == "2"
      return "1"
    else
      return missing
    end
  end
end


function feature_filter_one(a)
  if ismissing(a)
    return missing
  else
    if a == "1"
      return "1"
    elseif a == "0"
      return "0"
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
    if (gb133 == "1" && gb130 == "1") || (gb132 == "1" && gb130 == "2")
      return "0"
    elseif (gb131 == "1" && gb130 == "2") || (gb132 == "1" && gb130 == "1")
      return "1"
    else
	    return missing
    end
  end
end

transform!(data, [:GB130, :GB131, :GB132, :GB133] => ((a,b,c,d) -> VO_filter.(a,b,c,d)) => :VO)
transform!(data, [:GB327, :GB328] => ((a,b) -> feature_filter_one.(b)) => :NRc)
transform!(data, [:GB074, :GB075] => ((a,b) -> feature_filter_one.(a)) => :PN)
transform!(data, :GB193 => (a -> NA_filter.(a)) => :NA)


# add our new features to the values table
#
dd = stack(data[:, [:Language_ID, :VO, :NRc, :PN, :NA]], [:VO, :NRc, :PN, :NA])
rename!(dd, [:Language_ID, :Parameter_ID, :Value])
transform!(dd, [:Language_ID, :Parameter_ID] => ((a,b) -> b .* "-" .* a) => :ID)
transform!(dd, [:Value, :Parameter_ID] => ((a,b) -> b .* "-" .* a) => :Code_ID)
select!(dd, [:ID, :Language_ID, :Parameter_ID, :Value, :Code_ID])
dd.Comment .= "Reconstructed from other features"
dd.Source .= "the authors"
dd.Source_comment .= missing
dd.Coders .= missing
vals = [vals; dd]



# also need to add information about new features into codes table
#
push!(codes, ["VO-0", "VO", 0, "OV order"])
push!(codes, ["VO-1", "VO", 1, "VO order"])
push!(codes, ["NRc-0", "NRc", 0, "relative clauses prenominal"])
push!(codes, ["NRc-1", "NRc", 1, "relative clauses postnominal"])
push!(codes, ["PN-0", "PN", 0, "postpositions"])
push!(codes, ["PN-1", "PN", 1, "prepositions"])
push!(codes, ["NA-0", "NA", 0, "AdjN order"])
push!(codes, ["NA-1", "NA", 1, "NAdj order"])


# writeout
#
CSV.write("../tmp/grambank/values.csv", vals)
CSV.write("../tmp/grambank/codes.csv", codes)




