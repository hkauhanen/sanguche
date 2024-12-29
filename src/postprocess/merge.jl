using CSV
using DataFrames
using Serialization


try
    mkdir("../../results/")
catch e
end

wals = deserialize("../../wals/results/sand_results.jls")
gram = deserialize("../../grambank/results/sand_results.jls")

wals.dataset .= "WALS"
gram.dataset .= "Grambank"

both = innerjoin(wals, gram, on=:pair_ID, makeunique=true)

CSV.write("../../results/sand_results.csv", both)


