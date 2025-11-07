include("mecha.jl")

using ABCdeZ
using Serialization


emp = deserialize("../../results/wals/sand_results.jls")
emp = emp[1,:]


uni = Uniform(0.0, 1.0)
#uni = Beta(5.0, 20.0)
priors = [uni, uni, uni, uni, uni, uni, uni, uni, uni, uni, uni, uni, uni]
priors = Factored(priors...)


function error(predicted, empirical)
	pt = predicted[:tetrachoric]
	eDu = empirical.H_dispref - empirical.H
	eDo = empirical.H_pref - empirical.H

	tetrachoric_error = (pt["00"] - empirical.freq11)^2 + (pt["01"] - empirical.freq12)^2 + (pt["10"] - empirical.freq21)^2 + (pt["11"] - empirical.freq22)^2

	NE_error = (predicted[:Delta_under] - eDu)^2 + (predicted[:Delta_over] - eDo)^2

	total_error = tetrachoric_error + NE_error

	return isnan(total_error) ? 1000.0 : total_error
end


function dist!(x, ve)
	res = simulate(; N = 1000, d = 20, iter = 1000,
		       vert_prob = x[1],
		       v_rates1 = [x[2] x[3]; x[4] x[5]],
		       v_rates2 = [x[6] x[7]; x[8] x[9]],
		       h_rates = [x[10] x[11]; x[12] x[13]])

	error(res, emp), nothing
end


function abc(;
	prior = priors,
	epsilon = 0.01,
	alpha = 0.75,
	nsims_max = 50_000,
	nparticles = 500)
	
	abcdesmc!(prior, dist!, epsilon, nothing; α = alpha, nsims_max = nsims_max, nparticles = nparticles)

end


function summarize_abc_result(result; fun=median, digits=2)
	df = DataFrame(result.P[result.Wns .> 0.0])

	m = round.(fun.(eachcol(df)); digits=digits)

	return Dict(:vert_prob => m[1],
		    :v_rates1 => [m[2] m[3]; m[4] m[5]],
		    :v_rates2 => [m[6] m[7]; m[8] m[9]],
		    :h_rates => [m[10] m[11]; m[12] m[13]])
end


