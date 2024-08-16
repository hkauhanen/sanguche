dataset = "wals"

using CSV
using DataFrames
using Pipe
using Serialization

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

  fDict = Dict(
               "GB030" => "Gen",
               "GB302" => "Pas"
              )

  for k in keys(fDict)
    replace!(control_features, k => fDict[k])
  end

end


function stringtoset(s)
	Set(split(s, " & "))
end


correlations = CSV.read("../../results/$dataset/correlations.csv", DataFrame)
rename!(correlations, [:pair, :corrected_phi, :hpd])
transform!(correlations, :pair => (p -> replace.(p, "-" => " & ")) => :pair_pretty)
transform!(correlations, :pair_pretty => (p -> stringtoset.(p)) => :pair_ID)

results = CSV.read("../../results/$dataset/bfCorr.csv", DataFrame)

rename!(results, [:pair, :logBayes, :cpp])

transform!(results, :pair => (p -> replace.(p, "-" => " & ")) => :pair_pretty)

transform!(results, :pair => (p -> split.(p, "-")) => [:f1, :f2])

transform!(results, :pair_pretty => (p -> stringtoset.(p)) => :pair_ID)

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

transform!(results, [:interacting, :control] => ((i,c) -> classifier.(i,c)) => :status)


georesults = deserialize("../../../results/$dataset/results.jls")


allresults = innerjoin(results, georesults, on=:pair_ID, makeunique=true)
allresults = innerjoin(allresults, correlations, on=:pair_ID, makeunique=true)

tabletoprint = @pipe allresults |> subset(_, :degree => (d -> d .== 10)) |> select(_, [:pair_pretty, :N, :status, :logBayes, :cpp, :phi, :corrected_phi]) |> sort(_, :logBayes, rev=true)

transform!(tabletoprint, :phi => (p -> round.(p, digits=2)) => :phi)

rename!(tabletoprint, [:feature_pair, :sample_size, :status, :LBF, :CPP, :phi, :corrected_phi])


CSV.write("../../../results/$dataset/featuretable.csv", tabletoprint)
