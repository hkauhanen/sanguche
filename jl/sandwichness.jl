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


# compute isogloss density for type 'type'
@everywhere function isogloss_density(type, data, dists)
  # languages of this type
  datat = subset(data, :type => (t -> t .== type))

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

  # number of disagreeing neighbours (i.e. of differing types)
  isog = sum([cnts[k] for k in setdiff(keys(cnts), Set([type]))])

  # isogloss density
  return isog/total
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
  out.sd_distance .= std(distsh.distance)

  # mean isogloss densities for preferred and dispreferred types
  mid_pref = [isogloss_density(t, datah, distsh) for t in pref_types]
  out.mean_sigma_pref .= mean(mid_pref)
  mid_dispref = [isogloss_density(t, datah, distsh) for t in dispref_types]
  out.mean_sigma_dispref .= mean(mid_dispref)

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



select!(merged, Not(:f1_1, :f2_1, :class_1, :rep, :permuted))

# serialize results to file

serialize("../tmp/$dataset/sand_results.jls", merged)





