include("deps.jl")

dataset = ARGS[1]

samplerate = 10_000

using CSV
using DataFrames
using Random
using Serialization

Random.seed!(123459)

Ddists2 = deserialize("../tmp/$dataset/Ddists.jls")
Ddists = Dict()

fDict = Dict(
             "GB030" => "Gen",
             "GB302" => "Pas",
             "GB130" => "VS",
             "GB065" => "NG",
             "GB193" => "NA",
             "GB025" => "ND",
             "GB024" => "NNum",
             "GB059" => "AdPo",
             "GB068" => "AdjPr",
             "82A" => "VS",
             "83A" => "VO",
             "85A" => "PN",
             "86A" => "NG",
             "87A" => "NA",
             "88A" => "ND",
             "89A" => "NNum",
             "90A" => "NRc",
             "10A" => "Nas",
             "129A" => "HaAr",
             "116A" => "PolQ",
             "112A" => "NegM"
             )


for (key, val) in Ddists2
    Ddists[key] = val[shuffle(1:nrow(val))[1:samplerate], :]
end

for (key, val) in Ddists
    subset!(val, :eachindex => (k -> k .<= 100))

    val.f1 .= split(key, " & ")[1]
    val.f2 .= split(key, " & ")[2]
end

out = reduce(vcat, values(Ddists))

for k in keys(fDict)
    replace!(out.f1, k => fDict[k])
    replace!(out.f2, k => fDict[k])
end

out.pair .= out.f1 .* " & " .* out.f2

CSV.write("../tmp/$dataset/neighbour_distances.csv", out)
