cd(@__DIR__)

# do we downsample?
downsample = true
to_downsample = ["Austronesian", "Atlantic-Congo"]

# downsampling proportion
ds_rate = 0.75


include("features_grambank.jl")
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
    mkdir("../../grambank")
catch e
end

cd("../../grambank")

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
        mkdir("tmp/")
    catch e
    end

  gb = download(
                "https://zenodo.org/records/7844558/files/grambank/grambank-v1.0.3.zip?download=1",
                "tmp/grambank-v1.0.3.zip",
               )
  run(`unzip $gb -d tmp/`)
  gbdir = "grambank-grambank-7ae000c"
  cp("tmp/$gbdir/cldf/languages.csv", languagesF, force = true)
  cp("tmp/$gbdir/cldf/values.csv", valsF, force = true)
  cp("tmp/$gbdir/cldf/parameters.csv", paramsF, force = true)
  cp("tmp/$gbdir/cldf/codes.csv", codesF, force = true)
  rm("tmp", recursive = true)
end


##


# this function assists in downsampling. It attaches a random number between 0 and 1
# (uniform) to every Austronesian language, and zero to every other language. We then
# include all languages where this number is less than ds_rate (see top of this file)
# in the final dataset. ("deesse" = DS = downsampling.)
function deesse(x)
  if !ismissing(x)
    return x ∈ to_downsample ? rand() : 0
  else
    return 0
  end
end


##

languages = CSV.read(languagesF, DataFrame)

if downsample
  transform!(languages, :Family_name => (f -> deesse.(f)) => :filterer)
  filter!(x -> x.filterer < ds_rate, languages)
  CSV.write(languagesF, languages)
end

vals = CSV.read(valsF, DataFrame)

if downsample
  filter!(x -> x.Language_ID ∈ languages.ID, vals)
  CSV.write(valsF, vals)
end

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


# "?" values in Grambank are to be treated as missing values
data = mapcols(col -> replace(col, "?" => missing), data)


# because of the question marks (see above), the Grambank values have been
# read in as strings rather than numbers. But all code in the following
# expects integers. Hence, convert from string to int (i.e. parse)
for col in neededFeatures
    data[!, col] .= passmissing(parse).(Int64, data[!, col])
end


# Some Grambank features have values which start counting from 0, others
# start counting from 1. We need to homogenize this behaviour, so add 1
# to all features which start counting from 0
for col in neededFeatures
    if minimum(filter(x -> x.Parameter_ID == col, codes).Name) == 0
        data[!, col] .= data[!, col] .+ 1
    end
end


# GB193 (NA, order of noun and adjective) is such that it starts counting
# from 0 but we need to fish out values 1 and 2, i.e. we want values 2 and 3

function feature_filter_NA(a)
    if ismissing(a)
        return missing
    elseif a == 2
        return 1
    elseif a == 3
        return 2
    else
        return missing
    end
end


# Construct VO using GB130, GB131, GB132 and GB133.
# 
# Here it is important to note that GB130 starts numbering from 1,
# the others from 0.
#
# Using original Grambank values, the logic is:
# 
#   OV = (133:1 & 130:1) | (132:1 & 130:2)
#   VO = (131:1 & 130:2) | (132:1 & 130:1)
#
function VO_filter_classical(gb130, gb131, gb132, gb133)
    if ismissing(gb130) || ismissing(gb131) || ismissing(gb132) || ismissing(gb133)
        return missing
    else
        if (gb133 == 2 && gb130 == 1) || (gb132 == 2 && gb130 == 2)
            return 1
        elseif (gb131 == 2 && gb130 == 2) || (gb132 == 2 && gb130 == 1)
            return 2
        else
            return missing
        end
    end
end


function OV_prefilter(gb130, gb132, gb133)
    if ismissing(gb130) || ismissing(gb132) || ismissing(gb133)
        return missing
    elseif (gb133 == 2 && gb130 == 1) || (gb132 == 2 && gb130 == 2)
        return 1
    else
        return 0
    end
end

function VO_prefilter(gb130, gb131, gb132)
    if ismissing(gb130) || ismissing(gb131) || ismissing(gb132)
        return missing
    elseif (gb131 == 2 && gb130 == 2) || (gb132 == 2 && gb130 == 1)
        return 1
    else
        return 0
    end
end

function VO_filter(ov, vo)
    if ismissing(ov) || ismissing(vo)
        return missing
    elseif ov == 1 && vo == 1
        return missing
    elseif ov == 1
        return 1
    elseif vo == 1
        return 2
    else
        return missing
    end
end


# do the transforms
#
transform!(data, "GB193" => (a -> feature_filter_NA.(a)) => "NA")

transform!(data, [:GB130, :GB132, :GB133] => ((a,b,c) -> OV_prefilter.(a,b,c)) => :preOV)
transform!(data, [:GB130, :GB131, :GB132] => ((a,b,c) -> VO_prefilter.(a,b,c)) => :preVO)
transform!(data, [:preOV, :preVO] => ((a,b) -> VO_filter.(a,b)) => :VO)

#transform!(data, [:GB130, :GB131, :GB132, :GB133] => ((a,b,c,d) -> VO_filter_classical.(a,b,c,d)) => :VO)


select!(data, Not("GB193"))
select!(data, Not("GB131"))
select!(data, Not("GB132"))
select!(data, Not("GB133"))
select!(data, Not("preOV"))
select!(data, Not("preVO"))



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
push!(codes, ["VO-0", "VO", 0, "VO order"])
push!(codes, ["VO-1", "VO", 1, "OV order"])
push!(codes, ["NA-0", "NA", 0, "AN order"])
push!(codes, ["NA-1", "NA", 1, "NA order"])


# subsequent code expects a "Number" column in the codes table, as WALS has
codes[!, :Number] .= codes[!, :Name]


# writeout
#
#CSV.write(valsF, vals)
CSV.write(codesF, codes)
CSV.write(dataF, data)



