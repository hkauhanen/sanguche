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
	for grav in ["gravity", "plain"]
    for t in ["11", "12", "21", "22"]
        df = DataFrame(pair = r.pair, f1 = r.f1, f2 = r.f2, class = r.class, status = r.status, type = t, degree = r.degree, gravity = grav)
        
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

        df.identity_joins .= r["JC_$(t)_identity_$grav"]
        df.identity_joins_pvalue_less .= r["JC_$(t)_identity_pval_less_$grav"]
	df.identity_joins_sig_less .= ifelse(r["JC_$(t)_identity_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.identity_joins_pvalue_more .= r["JC_$(t)_identity_pval_more_$grav"]
	df.identity_joins_sig_more .= ifelse(r["JC_$(t)_identity_pval_more_$grav"] < CRITLEVEL, 1, 0)

        df.nonidentity_joins .= r["JC_$(t)_nonidentity_$grav"]
        df.nonidentity_joins_pvalue_less .= r["JC_$(t)_nonidentity_pval_less_$grav"]
	df.nonidentity_joins_sig_less .= ifelse(r["JC_$(t)_nonidentity_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.nonidentity_joins_pvalue_more .= r["JC_$(t)_nonidentity_pval_more_$grav"]
	df.nonidentity_joins_sig_more .= ifelse(r["JC_$(t)_nonidentity_pval_more_$grav"] < CRITLEVEL, 1, 0)

        df.underattested_joins .= r["JC_$(t)_underattested_$grav"]
        df.underattested_joins_pvalue_less .= r["JC_$(t)_underattested_pval_less_$grav"]
	df.underattested_joins_sig_less .= ifelse(r["JC_$(t)_underattested_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.underattested_joins_pvalue_more .= r["JC_$(t)_underattested_pval_more_$grav"]
	df.underattested_joins_sig_more .= ifelse(r["JC_$(t)_underattested_pval_more_$grav"] < CRITLEVEL, 1, 0)

        df.overattested_joins .= r["JC_$(t)_overattested_$grav"]
        df.overattested_joins_pvalue_less .= r["JC_$(t)_overattested_pval_less_$grav"]
        df.overattested_joins_sig_less .= ifelse(r["JC_$(t)_overattested_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.overattested_joins_pvalue_more .= r["JC_$(t)_overattested_pval_more_$grav"]
        df.overattested_joins_sig_more .= ifelse(r["JC_$(t)_overattested_pval_more_$grav"] < CRITLEVEL, 1, 0)

        df.valuelevel_f1_joins .= r["JC_$(t)_valuelevel_f1_$grav"]
        df.valuelevel_f1_joins_pvalue_less .= r["JC_$(t)_valuelevel_f1_pval_less_$grav"]
        df.valuelevel_f1_joins_sig_less .= ifelse(r["JC_$(t)_valuelevel_f1_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.valuelevel_f1_joins_pvalue_more .= r["JC_$(t)_valuelevel_f1_pval_more_$grav"]
        df.valuelevel_f1_joins_sig_more .= ifelse(r["JC_$(t)_valuelevel_f1_pval_more_$grav"] < CRITLEVEL, 1, 0)

        df.valuelevel_f2_joins .= r["JC_$(t)_valuelevel_f2_$grav"]
        df.valuelevel_f2_joins_pvalue_less .= r["JC_$(t)_valuelevel_f2_pval_less_$grav"]
        df.valuelevel_f2_joins_sig_less .= ifelse(r["JC_$(t)_valuelevel_f2_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.valuelevel_f2_joins_pvalue_more .= r["JC_$(t)_valuelevel_f2_pval_more_$grav"]
        df.valuelevel_f2_joins_sig_more .= ifelse(r["JC_$(t)_valuelevel_f2_pval_more_$grav"] < CRITLEVEL, 1, 0)

        df.valuelevel_either_joins .= r["JC_$(t)_valuelevel_either_$grav"]
        df.valuelevel_either_joins_pvalue_less .= r["JC_$(t)_valuelevel_either_pval_less_$grav"]
        df.valuelevel_either_joins_sig_less .= ifelse(r["JC_$(t)_valuelevel_either_pval_less_$grav"] < CRITLEVEL, 1, 0)
        df.valuelevel_either_joins_pvalue_more .= r["JC_$(t)_valuelevel_either_pval_more_$grav"]
        df.valuelevel_either_joins_sig_more .= ifelse(r["JC_$(t)_valuelevel_either_pval_more_$grav"] < CRITLEVEL, 1, 0)


        #=
        if df.class == "control" && df.attestation == "contingently underattested"
            df.pedigree .= "control_under"
        elseif df.classification == "dispreferred"
            df.pedigree .= "dispreferred"
        else
            df.pedigree .= "NA"
        end
        =#

        global longdata = vcat(longdata, df)
    end
    end
end


serialize("../../results/$dataset/joincounts.jls", longdata)
CSV.write("../../results/$dataset/joincounts.csv", longdata)
