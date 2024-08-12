dataset = "wals"

using CSV
using DataFrames
using Pipe

include("../../../jl/params.jl")

if dataset == "wals"
  control_features = control_features_wals

  fDict = Dict(
               "10A" => "Nas",
               "129A" => "HaAr"
              )

  for k in keys(fDict)
    replace!(control_features, k => fDict[k])
  end
else
  control_features = control_features_grambank
end


function stringtonumber(s)
	@pipe split(s, " & ") |> parse.(BigInt, _, base=62) |> sum
end




results = CSV.read("../../results/$dataset/bfCorr.csv", DataFrame)

rename!(results, [:pair, :logBayes, :cpp])

transform!(results, :pair => (p -> replace.(p, "-" => " & ")) => :pair_pretty)

transform!(results, :pair => (p -> split.(p, "-")) => [:f1, :f2])

transform!(results, :pair_pretty => (p -> stringtonumber.(p)) => :pair_ID)

transform!(results, :cpp => (p -> p .< 0.05) => :interacting)

transform!(results, [:f1, :f2] => ((a,b) -> a .∈ [control_features] .|| b .∈ [control_features]) => :control)

function classifier(i, c)
  if i && !c
    return "interacting"
  elseif !i && !c
    return "unknown"
  elseif !i && c
    return "non-interacting"
  else
    return "weird"
  end
end

transform!(results, [:interacting, :control] => ((i,c) -> classifier.(i,c)) => :class)





