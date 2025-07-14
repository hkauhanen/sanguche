using Pkg
Pkg.activate("Sanguche")

using CSV
using DataFrames

dataset = ARGS[1]

fam_freqs = CSV.read("../../$dataset/data/famFrequencies.csv", DataFrame)

# families with fewer than 3 members are done in RevBayes
subset!(fam_freqs, :nrow => (n -> n .> 2))

# excluded families (these ones refuse to converge no matter what we do)
excludes = open("fm_exclude_$dataset.txt", "r") do file
	readlines(file)
end

# remove exludes
subset!(fam_freqs, :glot_fam => (g -> g .∉ [excludes]))

# divide into large and small
large_fams = subset(fam_freqs, :nrow => (n -> n .>= 50))
small_fams = subset(fam_freqs, :nrow => (n -> n .< 50))

# order small families in increasing order
sort!(small_fams, :nrow, rev=false)

# write out
open("../../$dataset/data/fm_small.txt", "w") do file
  [println(file, fm) for fm in small_fams.glot_fam]
end

open("../../$dataset/data/fm_large.txt", "w") do file
  [println(file, fm) for fm in large_fams.glot_fam]
end


