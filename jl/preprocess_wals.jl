# download WALS
#

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



