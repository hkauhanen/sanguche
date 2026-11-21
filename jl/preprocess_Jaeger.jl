cd(@__DIR__)

using Pkg
Pkg.activate("JW")

##

try
    mkdir("../tmp")
catch e
end


download(
         "https://codeberg.org/profgerhard/comparison_wals_grambank/raw/branch/main/results/gbwals_all_pairs.csv",
         "../tmp/gbwals_all_pairs.csv")


