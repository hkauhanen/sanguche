using Distributed


# for a mysterious reason, we need to do the following to pass the 
# command-line argument to all worker processes; cf.
# https://discourse.julialang.org/t/how-to-pass-args-to-multiple-processes/80075/3
@everywhere myargfunc(x) = x
@everywhere dataset = myargfunc($ARGS)[1]


# all processors need access to the following
@everywhere using CSV
@everywhere using DataFrames
@everywhere using FreqTables
@everywhere using Random
@everywhere using Serialization
@everywhere using Statistics

@everywhere results = deserialize("../tmp/$dataset/grid.jls")
@everywhere Ddata = deserialize("../tmp/$dataset/Ddata.jls")
@everywhere Ddists = deserialize("../tmp/$dataset/Ddists.jls")


# count number of times each element of 'x' occurs in 'y'
@everywhere function levelcounter(x, y)
  out = Dict{Any,Int}()

  for elx in x
    out[elx] = 0
  end

  for elx in x
    for ely in y
      if ely == elx
        out[elx] = out[elx] + 1
      end
    end
  end

  out
end


# compute neighbourhood entropy for types in 'typeset'
@everywhere function NE(typeset, data, dists)
  # cycle through types
  # languages in typeset
  datat = subset(data, :type => (t -> t .∈ [typeset]))

  # their neighbours
  neighbours = subset(dists, :language_ID => a -> a .∈ [datat.Language_ID]).neighbour_ID

  if length(neighbours) == 0
    println("WARNING: empty neighbourhood (this shouldn't happen)")
  end

  # those neighbours' data
  datan = subset(data, :Language_ID => a -> a .∈ [neighbours])

  # counts of different types among those neighbours
  cnts = levelcounter(["11", "12", "21", "22"], datan.type)

  # total number of neighbours
  total = sum(values(cnts))

  # entropy
  entropy = 0
  for k in keys(cnts)
    if cnts[k] > 0
      entropy = entropy - (cnts[k]/total)*log2(cnts[k]/total)
    end
  end

  return entropy
end


# computes the various "sandwichness" metrics
@everywhere function sandwichness(r, results, Ddata, Ddists)
  resultsh = subset(results, :pair => (p -> p .== r.pair))
  datah = Ddata[r.pair]
  distsh = Ddists[r.pair]

  out = DataFrame(pair=r.pair)

  types = ["11", "12", "21", "22"]
  pref_types = []
  dispref_types = []
  for type in types
    if resultsh[1, "pref"*type] == 0
      push!(dispref_types, type)
    else
      push!(pref_types, type)
    end
  end

  out.H .= NE(types, datah, distsh)
  out.H_pref .= NE(pref_types, datah, distsh)
  out.H_dispref .= NE(dispref_types, datah, distsh)
  out.N .= nrow(datah)
  out.mean_distance .= mean(distsh.distance)

  return out
end


# number of feature pairs
@everywhere n_pairs = nrow(results)


# do the empirical thing: one repetition without shuffling, producing
# the empirical numbers

@everywhere reps = 1
@everywhere gridMC = repeat(results, reps)
@everywhere gridMC.rep = repeat(1:reps, inner=n_pairs)

sand = @distributed (vcat) for r in eachrow(gridMC)
  out = DataFrame(r)
  out = out[:, Between(:pair, :class)]
  out.rep .= r.rep

  out.permuted .= false

  geo_results = sandwichness(r, results, Ddata, Ddists)
  innerjoin(out, geo_results, on=:pair)
end



# finally, we figure out the summary statistics we're interested in

types = ["11", "12", "21", "22"]

merged = innerjoin(results, sand, on=:pair, makeunique=true)


#=
for df in [merged]
# "vintage" Xi measure, weighted by number of type types. Hacky solution, but I can't
# quickly think of a cleaner way of doing this...
df.Delta_pref .= 0.0
df.Delta_dispref .= 0.0
for r in 1:nrow(df)
NEs_pref = []
NEs_dispref = []
for type in types
if df[r, "pref"*type] == 0
push!(NEs_dispref, df[r, "H"] - df[r, "H"*type])
else
push!(NEs_pref, df[r, "H"] - df[r, "H"*type])
end
end
df[r,:].Delta_pref = sum(NEs_pref)/length(NEs_pref)
df[r,:].Delta_dispref = sum(NEs_dispref)/length(NEs_dispref)
end
end
=#


select!(merged, Not(:f1_1, :f2_1, :class_1, :rep, :permuted))

# serialize results to file

serialize("../tmp/$dataset/sand_results.jls", merged)
#serialize("../tmp/grand.jls", merged)





