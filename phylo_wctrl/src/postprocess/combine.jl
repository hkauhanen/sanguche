dataset = ARGS[1]

pvaluelimit = 0.05

using CSV
using DataFrames
using Pipe
using Serialization

try
  mkdir("../../../results/featuretables")
catch e
end


include("../../../jl/params.jl")

if dataset == "wals"
  control_features = control_features_wals

  fDict = Dict(
               #"10A" => "Nas",
               #"129A" => "HaAr"
               "116A" => "PolQ",
               "112A" => "NegM"
              )

  for k in keys(fDict)
    replace!(control_features, k => fDict[k])
  end
else
  control_features = control_features_grambank

  fDict = Dict(
               "GB030" => "Gen",
               "GB302" => "Pas"
               #"GB059" => "AdPo",
               #"GB068" => "AdjPr"
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

transform!(results, :cpp => (p -> p .< pvaluelimit) => :interacting)
#transform!(results, :cpp => (p -> p .< 0.1) => :interacting)

transform!(results, [:f1, :f2] => ((a,b) -> a .∈ [control_features] .|| b .∈ [control_features]) => :control)

function classifier_original(i, c)
  if i && !c
    return "interacting"
  elseif !i && !c
    return "unknown"
  elseif !i && c
    return "control"
  else
    return "weird"
  end
end

function classifier(i, c)
  if i
    return "interacting"
  elseif !i && !c
    return "unknown"
  elseif !i && c
    return "control"
  else
    return "weird"
  end
end

transform!(results, [:interacting, :control] => ((i,c) -> classifier.(i,c)) => :status)


#georesults = deserialize("../../../results/$dataset/results.jls")
georesults = CSV.read("../../../results/$dataset/results.csv", DataFrame)
transform!(georesults, :pair_pretty => (p -> stringtoset.(p)) => :pair_ID)


allresults = innerjoin(results, georesults, on=:pair_ID, makeunique=true)
allresults = innerjoin(allresults, correlations, on=:pair_ID, makeunique=true)

transform!(allresults, :phi => (p -> abs.(p)) => :abs_phi)
transform!(allresults, :corrected_phi => (p -> abs.(p)) => :abs_corrected_phi)


tabletoprint = @pipe allresults |> subset(_, :degree => (d -> d .== 1500)) |> select(_, [:pair_pretty, :N, :status, :logBayes, :cpp, :abs_phi, :abs_corrected_phi]) |> sort(_, :logBayes, rev=true)

transform!(tabletoprint, :abs_phi => (p -> round.(p, digits=2)) => :abs_phi)

rename!(tabletoprint, [:feature_pair, :sample_size, :status, :LBF, :CPP, :abs_phi, :abs_corrected_phi])

CSV.write("../../../results/featuretables/featuretable_$dataset.csv", tabletoprint, writeheader=false)

smalltabletoprint = @pipe subset(tabletoprint, :CPP => c -> c .< pvaluelimit) |> select(_, [:feature_pair, :sample_size, :LBF, :CPP, :abs_phi, :abs_corrected_phi]) |> rename(_, ["typology", "sample size", "LBF", "CPP", "\$|phi|\$", "\$|phi_c|\$"])

CSV.write("../../../results/featuretables/featuretable_interacting_$dataset.csv", smalltabletoprint, writeheader=false)

transform!(allresults, [:H, :H_pref] => ((a,b) -> b - a) => :Delta_over)
transform!(allresults, [:H, :H_dispref] => ((a,b) -> b - a) => :Delta_under)


tabletoprint = @pipe allresults |> subset(_, :degree => (d -> d .== 1500)) |> select(_, [:pair_pretty, :N, :status, :logBayes, :cpp, :abs_phi, :abs_corrected_phi, :Delta_over, :Delta_under]) |> sort(_, :logBayes, rev=true)

transform!(tabletoprint, :abs_phi => (p -> round.(p, digits=2)) => :abs_phi)
transform!(tabletoprint, :abs_corrected_phi => (p -> round.(p, digits=2)) => :abs_corrected_phi)
transform!(tabletoprint, :Delta_over => (p -> round.(p, digits=4)) => :Delta_over)
transform!(tabletoprint, :Delta_under => (p -> round.(p, digits=4)) => :Delta_under)

CSV.write("../../../results/featuretables/featuretable_withDelta_$dataset.csv", tabletoprint, writeheader=false)


log2_null(x) = log2(x) == -Inf ? 0.0 : log2(x)

binentropy(x,y) = -(x*log2_null(x) + y*log2_null(y))

transform!(allresults, [:freq11, :freq12, :freq21, :freq22] => ((f11, f12, f21, f22) -> 1.0 .- binentropy.(f11+f12, f21+f22)) => :skew1)
transform!(allresults, [:freq11, :freq12, :freq21, :freq22] => ((f11, f12, f21, f22) -> 1.0 .- binentropy.(f11+f21, f12+f22)) => :skew2)

transform!(allresults, [:skew1, :skew2, :Delta_under] => ((a,b,c) -> c ./ (1 .+ a .+ b)) => :D_under)
transform!(allresults, [:skew1, :skew2, :Delta_over] => ((a,b,c) -> c ./ (1 .+ a .+ b)) => :D_over)


bernoulli_skewness(p, q) = (q-p)/sqrt(p*q)


transform!(allresults, [:freq11, :freq12, :freq21, :freq22] => ((a,b,c,d) -> bernoulli_skewness.(a+b,c+d)) => :skewness1)
transform!(allresults, [:freq11, :freq12, :freq21, :freq22] => ((a,b,c,d) -> bernoulli_skewness.(a+c,b+d)) => :skewness2)
transform!(allresults, [:skewness1, :skewness2] => ((a,b) -> abs.(a) .+ abs.(b)) => :skewness)



allresults.dataset .= ""
if dataset == "wals"
    allresults.dataset .= "WALS"
else
    allresults.dataset .= "Grambank"
end

results_towrite = select(allresults, [:pair_pretty, :f1, :f2, :logBayes, :cpp, :interacting, :control, :skewness1, :skewness2, :skewness, :status, :phi, :abs_phi, :corrected_phi, :abs_corrected_phi, :hpd, :degree, :H, :H_pref, :H_dispref, :Delta_over, :Delta_under, :D_over, :D_under, :N, :mean_distance, :sd_distance, :dataset, :mean_nsize])

rename!(results_towrite, [:pair, :f1, :f2, :LBF, :CPP, :interacting, :control, :skewness1, :skewness2, :skewness, :status, :phi, :abs_phi, :corrected_phi, :abs_corrected_phi, :HPD, :k, :H, :H_over, :H_under, :Delta_over, :Delta_under, :D_over, :D_under, :N, :mean_distance, :sd_distance, :dataset, :mean_nsize])

CSV.write("../../../results/$dataset/results_combined.csv", results_towrite)

