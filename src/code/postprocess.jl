dataset = ARGS[1]

pvaluelimit_wals = 0.05
pvaluelimit_grambank = 0.05

pvaluelimit = dataset == "wals" ? pvaluelimit_wals : pvaluelimit_grambank

using Pkg

Pkg.activate("Sanguche")
Pkg.instantiate()


using CSV
using DataFrames
using Pipe
using Statistics


include("features_$dataset.jl")
include("params.jl")


try
	mkdir("../../results/featuretables")
catch e
end


# a couple of useful functions
stringtoset(s) = Set(split(s, " & "))
bernoulli_skewness(p, q) = (q-p)/sqrt(p*q)


# read in the phylogenetic results and the sandwichness results
phyl = CSV.read("../../results/$dataset/bfCorr.csv", DataFrame)
rename!(phyl, [:pair, :logBayes, :cpp])

corr = CSV.read("../../results/$dataset/correlations.csv", DataFrame)
rename!(corr, [:pair, :corrected_phi, :hpd])
corr.abs_corrected_phi = abs.(corr.corrected_phi)

sand = CSV.read("../../results/$dataset/sand_results.csv", DataFrame)


# construct pair IDs (sets of features)
transform!(phyl, :pair => (p -> replace.(p, "-" => " & ")) => :pair)
transform!(phyl, :pair => (p -> split.(p, " & ")) => [:f1, :f2])
transform!(phyl, :pair => (p -> stringtoset.(p)) => :pair_ID)

transform!(corr, :pair => (p -> replace.(p, "-" => " & ")) => :pair)
transform!(corr, :pair => (p -> split.(p, " & ")) => [:f1, :f2])
transform!(corr, :pair => (p -> stringtoset.(p)) => :pair_ID)

transform!(sand, :pair => (p -> stringtoset.(p)) => :pair_ID)


# feature pair statuses
transform!(phyl, :cpp => (p -> p .< pvaluelimit) => :interacting)
transform!(phyl, [:f1, :f2] => ((a,b) -> a .∈ [control_features] .|| b .∈ [control_features]) => :control)

function classifier(i, c)
	if i
		return "interacting"
	elseif !i && !c
		return "unknown"
	elseif !i && c
		return "non-interacting"
	else
		return "weird"
	end
end

transform!(phyl, [:interacting, :control] => ((i,c) -> classifier.(i,c)) => :status)


# combine all three tables
combined = innerjoin(phyl, sand, on=:pair_ID, makeunique=true)
combined = innerjoin(corr, combined, on=:pair_ID, makeunique=true)
combined.dataset .= dataset == "grambank" ? "Grambank" : "WALS"

combined.abs_phi = abs.(combined.phi)


# Delta measures
transform!(combined, [:H, :H_pref] => ((a,b) -> b - a) => :Delta_over)
transform!(combined, [:H, :H_dispref] => ((a,b) -> b - a) => :Delta_under)


# skewness measure
#=
transform!(combined, [:freq11, :freq12, :freq21, :freq22] => ((a,b,c,d) -> bernoulli_skewness.(a+b,c+d)) => :skewness1)
transform!(combined, [:freq11, :freq12, :freq21, :freq22] => ((a,b,c,d) -> bernoulli_skewness.(a+c,b+d)) => :skewness2)
transform!(combined, [:skewness1, :skewness2] => ((a,b) -> abs.(a) .+ abs.(b)) => :skewness)
=#

# writeout
CSV.write("../../results/$dataset/results_combined.csv", combined)


# print featuretables

function newname(s)
	s == "non-interacting" ? "control" : s
end
transform!(combined, :status => (s -> newname.(s)) => :status)

k = round(Int, sqrt(mean(combined.N)))

tabletoprint = @pipe combined |> subset(_, :degree => (d -> d .== k)) |> subset(_, :status => (s -> s .== "interacting")) |> select(_, [:pair, :N, :logBayes, :cpp, :abs_phi, :abs_corrected_phi]) |> sort(_, :logBayes, rev=true)

transform!(tabletoprint, :abs_phi => (p -> round.(p, digits=2)) => :abs_phi)

CSV.write("../../results/featuretables/featuretable_interacting_$dataset.csv", tabletoprint, writeheader=false)


tabletoprint = @pipe combined |> subset(_, :degree => (d -> d .== k)) |> select(_, [:pair, :N, :status, :logBayes, :cpp, :abs_phi, :abs_corrected_phi, :Delta_over, :Delta_under]) |> sort(_, :logBayes, rev=true)

transform!(tabletoprint, :abs_phi => (p -> round.(p, digits=2)) => :abs_phi)
transform!(tabletoprint, :Delta_over => (p -> round.(p, digits=5)) => :Delta_over)
transform!(tabletoprint, :Delta_under => (p -> round.(p, digits=5)) => :Delta_under)

CSV.write("../../results/featuretables/featuretable_withDelta_$dataset.csv", tabletoprint, writeheader=false)

if dataset == "grambank"
	#k = 10
	#tabletoprint = @pipe combined |> subset(_, :degree => (d -> d .== k)) |> select(_, [:pair, :N, :status, :logBayes, :cpp, :abs_phi, :abs_corrected_phi, :Delta_over, :Delta_under]) |> sort(_, :logBayes, rev=true)
	ell = -30
  tabletoprint = @pipe combined |> subset(_, [:degree, :N] => ((d,n) -> d .== round.(sqrt.(n), digits=0) .+ ell)) |> select(_, [:pair, :N, :status, :logBayes, :cpp, :abs_phi, :abs_corrected_phi, :Delta_over, :Delta_under]) |> sort(_, :logBayes, rev=true)

	transform!(tabletoprint, :abs_phi => (p -> round.(p, digits=2)) => :abs_phi)
	transform!(tabletoprint, :Delta_over => (p -> round.(p, digits=5)) => :Delta_over)
	transform!(tabletoprint, :Delta_under => (p -> round.(p, digits=5)) => :Delta_under)

  CSV.write("../../results/featuretables/featuretable_withDelta_$(dataset)_SN.csv", tabletoprint, writeheader=false)
end
