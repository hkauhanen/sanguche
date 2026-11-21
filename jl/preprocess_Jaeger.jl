cd(@__DIR__)

using Pkg
Pkg.activate("JW")

##

try
    mkdir("../tmp")
catch e
end


download("https://codeberg.org/profgerhard/comparison_wals_grambank/src/commit/7c7612897b894f2e70fdcd930ecb1fc217c4620b/results/gbwals_all_pairs.csv", "../tmp/gbwals_all_pairs.csv")


