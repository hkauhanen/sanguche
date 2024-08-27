# download WALS
#


include("deps.jl")


using CSV
using DataFrames
using Pipe
using Serialization


include("params.jl")

features = features_wals


try
    mkdir("../tmp")
catch e
end

try
    mkdir("../tmp/wals")
catch e
end


languagesF = "../tmp/wals/languages.csv"
valsF = "../tmp/wals/values.csv"
paramsF = "../tmp/wals/parameters.csv"
codesF = "../tmp/wals/codes.csv"


!(isfile(languagesF) && isfile(valsF) && isfile(paramsF)) && begin
    wals2020 = download(
                        "https://github.com/cldf-datasets/wals/archive/v2020.zip",
                        "../tmp/wals2020.zip",
                       )
    run(`unzip $wals2020 -d ../tmp/`)
    cp("../tmp/wals-2020/cldf/languages.csv", languagesF, force = true)
    cp("../tmp/wals-2020/cldf/values.csv", valsF, force = true)
    cp("../tmp/wals-2020/cldf/parameters.csv", paramsF, force = true)
    cp("../tmp/wals-2020/cldf/codes.csv", codesF, force = true)
end



#= From here on, we add our control features. The binarization scheme is:

116A Polar questions (PolQ)

Reduced to 'presence vs absence of question particles':

1 Question particle (585) YES
2 Interrogative verb morphology (164) NO
3 Question particle and interrogative verb morphology (15) YES
4 Interrogative word order (13) NO
5 Absence of declarative morphemes (4) NO
6 Interrogative intonation only (173) NO
7 No interrogative-declarative distinction (1) NO

YES  600
NO  355
TOTAL  955


112A  Negative morphemes (NegM)

Reduced to 'presence vs absence of negative affixes':

1 Negative affix (395) YES
2 Negative particle (502) NO
3 Negative auxiliary verb (47) NO
4 Negative word, unclear if verb or particle (73) NO
5 Variation between negative word and affix (21) YES
6 Double negation (119) EXCLUDED

YES  416
NO  622
EXCLUDED  119
TOTAL  1157
=#


languages = CSV.read(languagesF, DataFrame)

vals = CSV.read(valsF, DataFrame)

params = CSV.read(paramsF, DataFrame)

codes = CSV.read(codesF, DataFrame)
##


data = unstack(
               (@pipe vals |>
                filter(x -> x.Parameter_ID ∈ features, _) |>
                select(_, [:Language_ID, :Parameter_ID, :Value])),
               :Language_ID,
               :Parameter_ID,
               :Value,
              )

##



# filter used to construct PolQ
# 
function feature_filter_PolQ(a)
    if ismissing(a)
        return missing
    else
        if a == "1" || a == "3"
            return "1"
        else
            return "2"
        end
    end
end


# filter used to construct NegM
# 
function feature_filter_NegM(a)
    if ismissing(a)
        return missing
    else
        if a == "1" || a == "5"
            return "1"
        elseif a == "6"
            return missing
        else
            return "2"
        end
    end
end


transform!(data, "116A" => (a -> feature_filter_PolQ.(a)) => "116A")
transform!(data, "112A" => (a -> feature_filter_PolQ.(a)) => "112A")


#=
# add our new features to the values table
#
dd = stack(data[:, [:Language_ID, :VO, :NRc, :PN]], [:VO, :NRc, :PN])
rename!(dd, [:Language_ID, :Parameter_ID, :Value])
transform!(dd, [:Language_ID, :Parameter_ID] => ((a,b) -> b .* "-" .* a) => :ID)
transform!(dd, [:Value, :Parameter_ID] => ((a,b) -> b .* "-" .* a) => :Code_ID)
select!(dd, [:ID, :Language_ID, :Parameter_ID, :Value, :Code_ID])
dd.Comment .= "Reconstructed from other features"
dd.Source .= "the authors"
dd.Source_comment .= missing
dd.Coders .= missing
vals = [vals; dd]



# also need to add information about new features into codes table
#
push!(codes, ["VO-0", "VO", 0, "OV order"])
push!(codes, ["VO-1", "VO", 1, "VO order"])
push!(codes, ["NRc-0", "NRc", 0, "relative clauses prenominal"])
push!(codes, ["NRc-1", "NRc", 1, "relative clauses postnominal"])
push!(codes, ["PN-0", "PN", 0, "postpositions"])
push!(codes, ["PN-1", "PN", 1, "prepositions"])
=#

# writeout
#
CSV.write("../tmp/grambank/values.csv", vals)
CSV.write("../tmp/grambank/codes.csv", codes)




