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
	    df.classification .= (r.status == "interacting") ? "preferred" : "contingently overattested"
        elseif r["dispref$t"] == 1
            df.attestation .= "underattested"
	    df.classification .= (r.status == "interacting") ? "dispreferred" : "contingently underattested"
        else
            df.attestation .= "other"
	    df.classification .= "contingent other"
        end

        df.frequency .= r["freq$t"]

        df.status .= r.status

        df.identity_joins .= r["JC_$(t)_identity"]
        df.identity_joins_pvalue .= r["JC_$(t)_identity_pval"]
	df.identity_joins_sig .= ifelse(r["JC_$(t)_identity_pval"] < CRITLEVEL, 1, 0)

        df.nonidentity_joins .= r["JC_$(t)_nonidentity"]
        df.nonidentity_joins_pvalue .= r["JC_$(t)_nonidentity_pval"]
	df.nonidentity_joins_sig .= ifelse(r["JC_$(t)_nonidentity_pval"] < CRITLEVEL, 1, 0)

        df.underattested_joins .= r["JC_$(t)_underattested"]
        df.underattested_joins_pvalue .= r["JC_$(t)_underattested_pval"]
	df.underattested_joins_sig .= ifelse(r["JC_$(t)_underattested_pval"] < CRITLEVEL, 1, 0)

        df.overattested_joins .= r["JC_$(t)_overattested"]
        df.overattested_joins_pvalue .= r["JC_$(t)_overattested_pval"]
	df.overattested_joins_sig .= ifelse(r["JC_$(t)_overattested_pval"] < CRITLEVEL, 1, 0)

        global longdata = vcat(longdata, df)
    end
end


serialize("../../results/$dataset/joincounts.jls", longdata)
CSV.write("../../results/$dataset/joincounts.csv", longdata)
