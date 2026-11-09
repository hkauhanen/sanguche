#include("deps.jl")
using Pkg
Pkg.activate("Sanguche")

using CSV
using DataFrames
using Serialization
using Pipe


dataset = ARGS[1]

if length(ARGS) > 1
	JWflag = ARGS[2]
else
	JWflag = ""
end

CRITLEVEL = 0.05
LBFLEVEL = 4.0

sand = deserialize("../../results/$dataset/sand_results.jls")


#jawa = CSV.read("../../results/$dataset/bfCorr$(JWflag).csv", DataFrame)
#

jawa = CSV.read("../../results/gbwals_all_pairs.csv", DataFrame)

subset!(jawa, :dataset => (d -> lowercase.(d) .== dataset))

transform!(jawa, [:feat1, :feat2] => ByRow(((a,b) -> "$a-$b")) => :fpair)

transform!(jawa, :fpair => (fp -> Set.(split.(fp, "-"))) => :pair_ID)

data = innerjoin(sand, jawa, on = :pair_ID)

#data.status = ifelse.(data[!, "cumulative posterior probability"] .< CRITLEVEL, "interacting", "non-interacting")
data.status = ifelse.(data.lbf .> LBFLEVEL, "interacting", "non-interacting")

println(data[1:2, :])


longdata = DataFrame()

for r in eachrow(data)
	for nullhyp in ["globalnull", "familynull"]
		for expon in [0.0, 1.0, 2.0]
			for combination in ["f1", "f2", "AND", "OR", "XOR"]

				for t in ["11", "12", "21", "22"]
					df = DataFrame(pair = r.pair, f1 = r.f1, f2 = r.f2, class = r.class, status = r.status, type = t, degree = r.degree, combination = combination, gravity_exponent = expon, nullhypothesis = nullhyp)

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

					df.joincount .= r["JC_$(t)_$(combination)_GREX$(expon)_$(nullhyp)"]
					df.joins_pvalue_less .= r["JC_$(t)_$(combination)_pval_less_GREX$(expon)_$(nullhyp)"]
					df.joins_sig_less .= ifelse(r["JC_$(t)_$(combination)_pval_less_GREX$(expon)_$(nullhyp)"] < CRITLEVEL, 1, 0)
					df.joins_pvalue_more .= r["JC_$(t)_$(combination)_pval_more_GREX$(expon)_$(nullhyp)"]
					df.joins_sig_more .= ifelse(r["JC_$(t)_$(combination)_pval_more_GREX$(expon)_$(nullhyp)"] < CRITLEVEL, 1, 0)

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
	end
end


serialize("../../results/$dataset/joincounts$(JWflag).jls", longdata)
CSV.write("../../results/$dataset/joincounts$(JWflag).csv", longdata)
