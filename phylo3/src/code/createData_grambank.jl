dataset = "grambank"

include("../../../jl/params.jl")



cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.instantiate()

##
using CSV
using DataFrames
using Pipe
using DataStructures
using StatsBase
using ProgressMeter
using Missings
using Random
Random.seed!(2002261988307380348)

##
using Conda
Conda.pip_interop(true)
Conda.pip("install", "ete3")


ENV["PYTHON"] = ""
Pkg.build("PyCall")
using PyCall

ete3 = pyimport("ete3")

##

try
    mkdir("../data")
catch e
end



languagesF = "../../../tmp/$dataset/languages.csv"
valsF = "../../../tmp/$dataset/values.csv"
paramsF = "../../../tmp/$dataset/parameters.csv"
codesF = "../../../tmp/$dataset/codes.csv"


##

languages = CSV.read(languagesF, DataFrame)

vals = CSV.read(valsF, DataFrame)

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##


woFeatures = features_grambank


data = unstack(
    (@pipe vals |>
           filter(x -> x.Parameter_ID ∈ woFeatures, _) |>
           select(_, [:Language_ID, :Parameter_ID, :Value])),
    :Language_ID,
    :Parameter_ID,
    :Value,
)

##



  # some GB values are "?"; replace these with missing
  for i in 1:size(data,1), j in 2:size(data,2)
    if !ismissing(data[i,j]) && data[i,j] == "?"
      data[i,j] = missing
    end
  end

  # for some GB features, coding starts at 0. If so, increase all values by one
  for feat in names(data)[2:end]
    #if minimum(subset(codes, :Parameter_ID => p -> p .== feat).Name) == 0
    if minimum(filter(x -> x.Parameter_ID .== feat, codes).Name) == 0
      for r in 1:nrow(data)
        if !ismissing(data[r, feat]) && data[r, feat] == "0"
          data[r, feat] = "1"
        elseif !ismissing(data[r, feat]) && data[r, feat] == "1"
          data[r, feat] = "2"
        elseif !ismissing(data[r, feat]) && data[r, feat] == "2"
          data[r, feat] = "3"
        elseif !ismissing(data[r, feat]) && data[r, feat] == "3"
          data[r, feat] = "4"
        end
      end
    end
  end

  for i in 1:size(data,1), j in 2:size(data,2)
    v = data[i,j]
    if !ismissing(v) && isnothing(tryparse(Int, v))
      data[i,j] = missing
    elseif !ismissing(v) && parse(Int, v) > 2
      data[i,j] = missing
    end
  end



function adjustnumbering(n)
  if minimum(skipmissing(n)) == 0
    return n .+ 1
  else
    return n
  end
end


filter!(x -> x.Parameter_ID ∈ woFeatures, codes)

codes = combine(groupby(codes, :Parameter_ID), :ID, :Name, :Name => (n -> adjustnumbering(n)) => :Number)

select!(codes, [:ID, :Parameter_ID, :Name, :Number])


filter!(x -> x.Number ∈ [1,2], codes)
##
#


# the next for loop expects feature values as numerics, so we parse
# the strings into numbers
#
data2 = passmissing(tryparse).(Int, data[:, 2:end])
data2[:, :Language_ID] .= data.Language_ID
data = data2


for i in 1:size(data,1), j in 1:(size(data,2)-1)
    v = data[i,j]
    if !ismissing(v) && v > 2
        data[i,j] = missing
    end
end


##
nValues = vec(length(woFeatures) .- mapslices(x -> sum(ismissing.(x)), Array(data), dims=2))
insertcols!(data, 10, :nValues => nValues)

sort!(data, :nValues, rev=true)

##

dropmissing!(languages, :Glottocode)

data = innerjoin(
    data,
    select(languages, [:ID, :Glottocode]),
    on = :Language_ID => :ID,
)

unique!(data, :Glottocode)

filter!(x -> x.nValues >= 6, data)

##


try
    mkdir("../data/asjp")
catch e
end



languagesF = "../data/asjp/languages.csv"

!isfile(languagesF) && begin
    try
        mkdir("tmp")
    catch e
    end

    asjp18 = download(
        "https://zenodo.org/record/3835952/files/lexibank/asjp-v18.zip",
        "tmp/asjp-v18.zip",
    )
    run(`unzip $asjp18 -d tmp/`)
    cp("tmp/lexibank-asjp-fb8987f/cldf/languages.csv", languagesF, force = true)
    rm("tmp", recursive = true)
end
asjp = CSV.read("../data/asjp/languages.csv", DataFrame)

##

longnames =
    [replace(r.classification_wals * "." * r.Name, "-" => "_") for r in eachrow(asjp)]

insertcols!(asjp, 2, :longname => longnames)

data = innerjoin(
    dropmissing(select(asjp, [:Glottocode, :longname])),
    data,
    on = :Glottocode,
)

##


asjp18ClusteredF = download(
    "https://osf.io/tdma5/download",
    "../data/asjp18Clustered.csv",
)

asjp18Clustered = CSV.read(asjp18ClusteredF, DataFrame)

asjp18Clustered[:,:glot_fam] = replace.(asjp18Clustered.glot_fam, "'" => "_")


longnames = [
    replace(join([r.wls_fam, r.wls_gen, r.doculect], "."), "-" => "_") for
    r in eachrow(asjp18Clustered)
]

insertcols!(asjp18Clustered, 2, :longname => longnames)
##
ln2g = unique(select(asjp18Clustered, [:longname, :glot_fam]))
data = innerjoin(data, ln2g, on=:longname)

##

taxa = unique(data.longname)
taxa = [x for x in taxa if x in asjp18Clustered.longname]

asjpCC = filter(x -> x.longname ∈ taxa, asjp18Clustered)



data = filter(x -> x.longname ∈ taxa, data)

fDict = Dict(
    "GB130" => "VS",
    "GB065" => "NG",
    "GB193" => "NA",
    "GB025" => "ND",
    "GB024" => "NNum",
    "GB030" => "Gen",
    "GB302" => "Pas"
)


rename!(data, fDict)

select!(data, [:longname, :glot_fam, :VS, :VO, :PN, :NG, :NA, :ND, :NNum, :NRc, :Gen, :Pas])






CSV.write("../data/charMtx.csv", data)

##

features = names(data)[3:end]

fPairs = [
    join([f1, f2], "-") for (i, f1) in enumerate(features) for
    (j, f2) in enumerate(features) if i < j
]

open("../data/fpairs.txt", "w") do file
    for fp in fPairs
        write(file, fp)
        write(file, "\n")
    end
end
##


famFreqs = sort(combine(groupby(data, :glot_fam), nrow), :nrow, rev=true)


open("../data/families.csv", "w") do file
    write(file, join(famFreqs.glot_fam, "\n"))
    write(file, "\n")
end


glot2Plus = filter(x -> x.nrow > 1, famFreqs).glot_fam

isolates = filter(x -> x.nrow == 1, famFreqs).glot_fam

# open("../data/isolates.csv", "w") do file
#     write(file, join(isolates, "\n"))
#     write(file, "\n")
# end
#


CSV.write("../data/famFrequencies.csv", famFreqs)


##

codingDict = Dict(
    (missing, missing) => "-",
    (missing, 1) => "-",
    (missing, 2) => "-",
    (1, missing) => "-",
    (2, missing) => "-",
    (1,1) => "a",
    (1,2) => "b",
    (2,1) => "c",
    (2,2) => "d",
)

##

pairMtx = DataFrame(taxon = taxa)
for fp in fPairs
    f1, f2 = Symbol.(split(fp, "-"))
    insertcols!(
        pairMtx,
        fp => [codingDict[x] for x in zip(data[:, f1], data[:, f2])],
    )
end

CSV.write("../data/fpairMtx.csv", pairMtx)

##

try
    mkdir("../data/posteriorTrees")
catch e
end

for fm in isolates
    l = first(filter(x -> x.glot_fam == fm, data).longname)
    nex = "($l:.01, dummy:.01);"
    open("../data/posteriorTrees/" * fm * ".posterior.tree", "w") do file
        write(file, nex)
    end
end



##

worldGlotF = download("https://osf.io/jyvgt/download", "../data/world_fullGlot.tre")

glot = ete3.Tree(worldGlotF)

glot.prune(taxa)

##

concepts = unique(asjpCC.concept)

sounds = first.(sort(unique(split(join(asjpCC.simplified), ""))))


df = @pipe asjpCC |>
      select(_, [:longname, :concept, :simplified]) |>
      groupby(_, [:longname, :concept]) |>
      combine(_, :simplified => join => :words) |>
      unstack(_, :longname, :concept, :words)

scDict = Dict()
@showprogress for (i,l) in enumerate(taxa), (j,c) in enumerate(concepts), s in sounds
    if ismissing(df[i, j+1])
        scDict[l,c,s] = "-"
    else
        scDict[l,c,s] = Int(s ∈ df[i, j+1])
    end
end


##


asjpCC = filter(x -> x.longname ∈ taxa, asjp18Clustered)

try
    mkdir("../data/asjpNex/")
catch e
end

try
    mkdir("../data/asjpNex/output")
catch e
end


glot3 = filter(x->x.nrow>2, famFreqs).glot_fam

open("../data/glot3.txt", "w") do file
    write(file, join(glot3, "\n")*"\n")
end


##

ccc = unique(asjpCC.cClass)

lc = Dict()
for l in taxa, c in concepts
    lc[l,c] = false
end

for (l,c) in zip(asjpCC.longname, asjpCC.concept)
    lc[l,c] = true
end

cc2c = Dict(zip(asjpCC.cClass, asjpCC.concept))

ccDict = Dict()
@showprogress for l in taxa, cc in ccc
    if lc[l, cc2c[cc]]
        ccDict[l,cc] = "0"
    else
        ccDict[l,cc] = "-"
    end
end

for (l, cc) in zip(asjpCC.longname, asjpCC.cClass) |> unique
    ccDict[l, cc] = "1"
end

ccMtx = Array{String}(undef, size(taxa,1), size(ccc,1))
@showprogress for (i,l) in enumerate(taxa), (j,cc) in enumerate(ccc)
    ccMtx[i,j] = ccDict[l,cc]
end
##

l2glot = Dict(zip(asjpCC.longname, asjpCC.glot_fam))

famV = [l2glot[l] for l in taxa]
##

scChar_ = []
@showprogress for c in concepts
    sChar = Array{String}(undef, length(taxa), length(sounds))
    for (i,l) in enumerate(taxa), (j,s) in enumerate(sounds)
        sChar[i,j] = string(scDict[l,c,s])
    end
    push!(scChar_, sChar)
end

scMtx = hcat(scChar_...)

##

@showprogress for fm in glot3
    fmTaxa = taxa[famV .== fm]
    ccChar = ccMtx[famV .== fm,:]
    scChar = scMtx[famV .== fm,:]
    charMtx = hcat(ccChar, scChar)
    pad = maximum(length.(fmTaxa))+5
    nex = """
#NEXUS

BEGIN DATA;
DIMENSIONS ntax=$(length(fmTaxa)) NCHAR=$(size(charMtx,2));
FORMAT DATATYPE=restriction GAP=? MISSING=- interleave=yes;
MATRIX

"""
    for (i,l) in enumerate(fmTaxa)
        nex
        nex *= rpad(l, pad)
        nex *= join(charMtx[i,:])
        nex *= "\n"
    end
    nex *= """

;

END;
"""
    open("../data/asjpNex/"*fm*".nex", "w") do file
        write(file, nex)
    end
end
##

try
    mkdir("revbayes")
catch e
end

glot2 = filter(x -> x.nrow==2, famFreqs).glot_fam

@showprogress for fm in glot2
    fmTaxa = taxa[famV .== fm]
    ccChar = ccMtx[famV .== fm,:]
    scChar = scMtx[famV .== fm,:]
    charMtx = hcat(ccChar, scChar)

    pad = maximum(length.(fmTaxa))+5
    nex = """
#NEXUS

BEGIN DATA;
DIMENSIONS ntax=$(length(fmTaxa)) NCHAR=$(size(charMtx,2));
FORMAT DATATYPE=restriction GAP=? MISSING=- interleave=yes;
MATRIX

"""
    for (i,l) in enumerate(fmTaxa)
        nex
        nex *= rpad(l, pad)
        nex *= join(charMtx[i,:])
        nex *= "\n"
    end
    nex *= """

;

END;
"""

    open("../data/asjpNex/"*fm*".nex", "w") do file
        write(file, nex)
    end
rb = """
family = "$fm"
source("../phylogeny.Rev")
"""
    open("revbayes/$(fm).Rev", "w") do file
        write(file, rb)
    end
end

##


geoData = innerjoin(
    data[:, [:longname, :glot_fam]],
    asjp[:, [:longname, :Longitude, :Latitude]],
    on=:longname
)

CSV.write("../data/geoData.csv", geoData)
