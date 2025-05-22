# Makes the dataframe that collects all our results, each row representing
# one unique combination of features. Additionally adds summary statistics
# such as (plain) phi coefficients and type frequencies.
#


using Pkg
Pkg.activate("Sanguche")


using CodecZlib
using Combinatorics
using CSV
using DataFrames
using FreqTables
using HypothesisTests
using Statistics
using Serialization
using StatsBase
using Distributions


dataset = ARGS[1]
limtype = ARGS[2]

include("features_$dataset.jl")
include("params.jl")


# alpha is defined in params.jl
dispref_alpha = alpha
pref_alpha = alpha


if dataset == "wals"
    cd("../../wals")
else
    cd("../../grambank")
end

try
    mkdir("./dicts/")
catch e
end


pairs = combinations(features_pretty, 2)

results = DataFrame(pair=[v[1] * " & " * v[2] for v in pairs],
                    f1=[v[1] for v in pairs], 
                    f2=[v[2] for v in pairs])


# If one of the features in the pair is in 'control_features', the pair is a control.
# Else, it is a target pair.
f1s = [f in control_features for f in results[:, :f1]]
f2s = [f in control_features for f in results[:, :f2]]
results.class = ifelse.(f1s .+ f2s .> 0, "control", "target")



data = CSV.read("./data/data.csv", DataFrame)


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

results.pref11 .= 0
results.pref12 .= 0
results.pref21 .= 0
results.pref22 .= 0

results.dispref11 .= 0
results.dispref12 .= 0
results.dispref21 .= 0
results.dispref22 .= 0

results.pref11_pval .= 1.0
results.pref12_pval .= 1.0
results.pref21_pval .= 1.0
results.pref22_pval .= 1.0

results.dispref11_pval .= 1.0
results.dispref12_pval .= 1.0
results.dispref21_pval .= 1.0
results.dispref22_pval .= 1.0


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
        # make a copy of contingency table
        conthere = copy(cont)

      # frequency of this type
      results[r, "freq" * string(x) * string(y)] = prop(conthere)[x,y]

      # number of languages with feature 1 == "off"
      local Ni = sum(conthere[x,:])

      # number of languages with feature 2 == "off"
      local Nj = sum(conthere[:,y])

      # number of languages with off-off
      local X = conthere[x,y]
      
      # total number of languages in contingency table
      local N = sum(conthere)

      # probability of less than X languages in off-off state
      dis = Distributions.Hypergeometric(Ni, N - Ni, Nj)
      local pval = sum([Distributions.pdf(dis, y) for y in 0:X])

      # probability of more than X languages in off-off state
      local pval2 = sum([Distributions.pdf(dis, y) for y in X:N])

      results[r, "dispref" * string(x) * string(y) * "_pval"] = pval
      results[r, "pref" * string(x) * string(y) * "_pval"] = pval2

      if pval < dispref_alpha
          results[r, "dispref" * string(x) * string(y)] = 1
      end
      if pval2 < pref_alpha
          results[r, "pref" * string(x) * string(y)] = 1
      end
    end
  end
end

if !isfile("./dicts/dists.csv.gz")
  if dataset == "wals"
    download("https://raw.githubusercontent.com/hkauhanen/wals-distances/master/wals-distances.csv.gz", "./dicts/dists.csv.gz")
  elseif dataset == "grambank"
    download("https://raw.githubusercontent.com/hkauhanen/grambank-distances/main/grambank-distances-under5000km.csv", "./dicts/dists.csv.gz")
    #cp("/home/hkauhanen/Work/grambank-distances-random/grambank-distances-under5000km.csv", "./dicts/dists.csv")
  end
end

dists = CSV.read("./dicts/dists.csv.gz", DataFrame)

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
  
  if limtype == "rank"
    tmp2 = subset(tmp2, :eachindex => i -> i .<= maximum(degrees))
  elseif limtype == "km"
    tmp2 = subset(tmp2, :distance => i -> i .<= maximum(degrees))
  else
    println("invalid limtype!")
  end

  Ddata[r.pair] = tmp
  Ddists[r.pair] = tmp2
end


# expand grid ('results') so that each data point has a row for each degree
grid = DataFrame()
for degree in degrees
  local here = results
  here.degree .= degree
  global grid = [grid; here]
end




serialize("./dicts/grid.jls", grid)
serialize("./dicts/Ddata.jls", Ddata)
serialize("./dicts/Ddists.jls", Ddists)



