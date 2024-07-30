
# Makes the dataframe that collects all our results, each row representing
# one unique combination of features. Additionally adds summary statistics
# such as (plain) phi coefficients and type frequencies.
#


using CodecZlib
using Combinatorics
using CSV
using DataFrames
using FreqTables
using HypothesisTests
using Statistics
using Serialization
using StatsBase


dataset = ARGS[1]
min_degree = parse(Int, ARGS[2])
max_degree = parse(Int, ARGS[3])

include("features_$dataset.jl")


pairs = combinations(features, 2)

results = DataFrame(pair=[v[1] * " & " * v[2] for v in pairs],
                    f1=[v[1] for v in pairs], 
                    f2=[v[2] for v in pairs])


# If one of the features in the pair is in 'control_features', the pair is a control.
# Else, it is a target pair.
f1s = [f in control_features for f in results[:, :f1]]
f2s = [f in control_features for f in results[:, :f2]]
results.class = ifelse.(f1s .+ f2s .> 0, "control", "target")



data = deserialize("../tmp/$dataset/data.jls")


# function to calculate phi coefficient for a matrix/contingency table
function phi_coefficient(x)
  (x[1,1]*x[2,2] - x[1,2]*x[2,1])/sqrt(sum(x[1,:])*sum(x[2,:])*sum(x[:,1])*sum(x[:,2]))
end


# we now add a number of summary statistics:
# - phi coefficient
# - p-value from Fisher's exact test for the above
# - frequencies of types for each feature pair
# - information about preferred/dispreferred status

results.phi .= 0.0
results.phi_pvalue .= 0.0
results.freq11 .= 0.0
results.freq12 .= 0.0
results.freq21 .= 0.0
results.freq22 .= 0.0

# 0 means dispreferred, 1 means preferred
results.pref11 .= 0
results.pref12 .= 0
results.pref21 .= 0
results.pref22 .= 0

for r in 1:nrow(results)
  # contingency table for features on row 'r' of results table
  cont = freqtable(data[:, results[r, :f1]], data[:, results[r, :f2]], skipmissing=true)

  # phi coefficient
  results[r, :phi] = phi_coefficient(cont)

  # p-value from Fisher's exact test
  results[r, :phi_pvalue] = pvalue(FisherExactTest(Matrix(cont)...))

  # add type frequencies and preference status
  for x in 1:2
    for y in 1:2
      prophere = prop(cont)[x,y]
      results[r, "freq" * string(x) * string(y)] = prophere
      if prophere >= 0.25
        results[r, "pref" * string(x) * string(y)] = 1
      end
    end
  end
end

if !isfile("../tmp/$dataset/dists.csv")
  if dataset == "wals"
    download("https://raw.githubusercontent.com/hkauhanen/wals-distances/master/wals-distances-under5000km.csv", "../tmp/$dataset/dists.csv")
  elseif dataset == "grambank"
    download("https://raw.githubusercontent.com/hkauhanen/grambank-distances/main/grambank-distances-under5000km.csv", "../tmp/$dataset/dists.csv")
  end
end

dists = CSV.read("../tmp/$dataset/dists.csv", DataFrame)

Ddata = Dict()
Ddists = Dict()

for r in eachrow(results)
  local tmp = data[:, ["Language_ID", r.f1, r.f2]]
  dropmissing!(tmp)
  transform!(tmp, [r.f1, r.f2] => ((a,b) -> string.(a) .* string.(b)) => :type)

  local tmp2 = subset(dists, :language_ID => (a -> a .∈ [tmp.Language_ID]))
  tmp2 = subset(tmp2, :neighbour_ID => (a -> a .∈ [tmp.Language_ID]))

  tmp = subset(tmp, :Language_ID => (a -> a .∈ [tmp2.language_ID]))

  tmp2 = combine(groupby(tmp2, :language_ID), :neighbour_ID, :distance, eachindex)
  tmp2 = subset(tmp2, :eachindex => i -> i .<= max_degree)

  Ddata[r.pair] = tmp
  Ddists[r.pair] = tmp2
end


# expand grid ('results') so that each data point has a row for each
# degree between 'min_degree' and 'max_degree'
grid = DataFrame()
for degree in min_degree:max_degree
	local here = results
	here.degree .= degree
	global grid = [grid; here]
end




serialize("../tmp/$dataset/grid.jls", grid)
serialize("../tmp/$dataset/Ddata.jls", Ddata)
serialize("../tmp/$dataset/Ddists.jls", Ddists)



