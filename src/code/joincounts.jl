#include("deps.jl")
using Pkg
Pkg.activate("Sanguche")

using CSV
using DataFrames
using Serialization
using Pipe


dataset = "wals"

CRITLEVEL = 0.05


sand = deserialize("../../results/$dataset/sand_results.jls")

jawa = CSV.read("../../results/$dataset/bfCorr.csv", DataFrame)

transform!(jawa, "feature pair" => (fp -> Set.(split.(fp, "-"))) => :pair_ID)

data = innerjoin(sand, jawa, on = :pair_ID)

data.status = ifelse.(data[!, "cumulative posterior probability"] .< CRITLEVEL, "interacting", "non-interacting")


longdata = DataFrame()

for r in eachrow(data)
    for t in ["11", "12", "21", "22"]
        df = DataFrame(pair = r.pair, f1 = r.f1, f2 = r.f2, status = r.status, type = t)
        
        if r["pref$t"] == 1
            df.attestation .= "overattested"
        elseif r["dispref$t"] == 1
            df.attestation .= "underattested"
        else
            df.attestation .= "other"
        end

        df.frequency .= r["freq$t"]

        df.status .= r.status

        df.identity_joins .= r["JC_$(t)_$t"]
        df.identity_joins_pvalue .= r["JC_$(t)_$(t)_pval"]

        non_identity_joins = 0.0
        for s in ["11", "12", "21", "22"]
            if s != t
                non_identity_joins += r["JC_$(t)_$(s)"]
            end
        end
        df.non_identity_joins .= non_identity_joins

        global longdata = vcat(longdata, df)
    end
end


serialize("../../results/$dataset/joincounts.jls", longdata)
CSV.write("../../results/$dataset/joincounts.csv", longdata)
