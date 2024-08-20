include("deps.jl")


using Serialization
using CSV
using DataFrames
using Pipe


dataset = ARGS[1]


fDict = Dict(
             "GB030" => "Gen",
             "GB302" => "Pas",
             "GB130" => "VS",
             #"VO" => "VO",
             "GB065" => "NG",
             "GB193" => "NA",
             "GB025" => "ND",
             "GB024" => "NNum",
             #"NRc" => "NRc",
             "82A" => "VS",
             "83A" => "VO",
             "85A" => "PN",
             "86A" => "NG",
             "87A" => "NA",
             "88A" => "ND",
             "89A" => "NNum",
             "90A" => "NRc",
             "10A" => "Nas",
	     "129A" => "HaAr"
	     )
 
grand = deserialize("../tmp/$dataset/sand_results.jls")

grand.f1_pretty .= grand.f1
grand.f2_pretty .= grand.f2

for k in keys(fDict)
  replace!(grand.f1_pretty, k => fDict[k])
  replace!(grand.f2_pretty, k => fDict[k])
end

grand.pair_pretty .= grand.f1_pretty .* " & " .* grand.f2_pretty


# add JW's estimates and conclusions
#
# This takes some ingenuity, as we need to represent feature pairs as sets
# (i.e. unordered pairs). We translate strings such as "VO" into integers,
# then take the sum to represent the pair (of course, inside Julia, we could
# just use Sets, but we want to be able to merge dataframes by a unique
# identifier which refers to the feature pair also in other environments,
# such as in R).
#
# On the string-to-number translation, consult
# https://stackoverflow.com/questions/49415718/representing-a-non-numeric-string-as-in-integer-in-julia

JW = CSV.read("../aux/JW.csv", DataFrame)

function stringtonumber(s)
	Set(split(s, " & "))
	#@pipe split(s, " & ") |> parse.(BigInt, _, base=62) |> sum
end

transform!(JW, :pair_pretty => (p -> stringtonumber.(p)) => :pair_ID)
transform!(grand, :pair_pretty => (p -> stringtonumber.(p)) => :pair_ID)

grand = leftjoin(grand, JW, on=:pair_ID, makeunique=true)

grand.okay .= string.(grand.okay_JW)
#grand.okay .= ifelse.(grand.okay .== "missing", "unknown", grand.okay)
grand.okay .= ifelse.(grand.okay .== "missing", "non-interacting", grand.okay)
grand.okay .= ifelse.(grand.okay .== "0", "unknown", grand.okay)
grand.okay .= ifelse.(grand.okay .== "1", "interacting", grand.okay)

#tmp_assumption = ifelse.(ismissing.(grand.okay_JW), 0, grand.okay_JW)
#grand.okay_assumption .= ifelse.(tmp_assumption .== 0, "not credible", "credible")


try
  mkdir("../results")
catch e
end

try
  mkdir("../results/$dataset")
catch e
end


# write out
serialize("../results/$dataset/results.jls", grand)
CSV.write("../results/$dataset/results.csv", grand)
