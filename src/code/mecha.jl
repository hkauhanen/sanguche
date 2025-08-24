using Pkg
Pkg.activate("Sanguche")

using Agents
using DataFrames
using Distributions
using FreqTables
using Graphs
using Pipe
using StatsBase


# count number of times each element of 'x' occurs in 'y'
function levelcounter(x, y)
    out = Dict{Any,Float64}()

    for elx in x
        out[elx] = 0
    end

    for elx in x
        for ely in y
            if ely == elx
                out[elx] = out[elx] + 1
            end
        end
    end

    out
end





# data structure for languages
@agent struct Language(GraphAgent)
	f::Vector{Int}
end


# flip a feature value (0 becomes 1, 1 becomes 0)
function flip!(agent::Language, which::Int)
	agent.f[which] = abs(agent.f[which] - 1)
end


# agent stepping function
function mystep!(agent::Language, model)
	# which feature to target
	target, donor = sample(1:2, 2, replace=false)

	if rand() < model.vert_prob
		# vertical event

		# target's value
		tarval = agent.f[target]

		# donor's value
		donval = agent.f[donor]

		# flip with relevant vertical probability
		if rand() < model.v_rates[target][tarval + 1, donval + 1]
			flip!(agent, target)
		end
	else
		# horizontal event

		# pick a neighbour at random
		neighbour = random_nearby_agent(agent, model)

		# observe neighbour's value for target feature
		value = neighbour.f[target]

		# copy that value to focal language with relevant hor. probability
		if rand() < model.h_rates[target, value + 1]
			agent.f[target] = value
		end
	end
end


# compute tetrachoric table from DataFrame outputted by Agents.run!
#=
function get_tetrachoric(data)
	join.(data.f) |> freqtable
end
=#
function get_tetrachoric(data; prop = false)
	tabu = levelcounter(["00", "01", "10", "11"], join.(data.f))

	if prop
		for k in keys(tabu)
			tabu[k] = tabu[k] / sum(values(tabu))
		end
	end

	tabu
end


# compute neighbourhood entropy given type belongs to type set S
function NE(S; model, data)
	# type as string (00, 01 etc.)
	data.type = join.(data.f)

	# languages in type set S
	S_lang = subset(data, :type => ty -> ty .∈ [S]).id

	# frequencies of different type languages in neighbourhoods
	freqs = Dict("00" => 0,
		     "01" => 0,
		     "10" => 0,
		     "11" => 0)

	# for each language in S_lang, increment the frequency counters
	for id in S_lang
		# the neighbours
		neighbours = nearby_ids(model[id], model)

		# their types
		nei_types = subset(data, :id => i -> i .∈ [neighbours]) |> get_tetrachoric

		# increment counters
		for k in keys(freqs)
			# we try-catch this, since it is possible that some type in
			# nei_types has a zero count, i.e. does not exist in nei_types
			try
				freqs[k] += nei_types[k]
			catch
			end
		end
	end

	# compute entropy
	probs = values(freqs) ./ sum(values(freqs))
	H = -sum(probs .* log2.(probs))

	# return
	H
end


# identify underattested and overattested types
function attestations(data; alpha = 0.5)
	# overattested
	oa = []

	# underattested
	ua = []

	# neither
	ne = []

	# tetrachoric table
	tetra = get_tetrachoric(data)

	# possible types, in vector format
	types = [[0,0], [0,1], [1,0], [1,1]]

	for t in types # where t = [i,j]
		i = t[1]
		j = t[2]

		# number of languages with f1 = i
		Ni = 0
		try
			Ni = tetra[join([i, "0"])] + tetra[join([i, "1"])]
		catch
		end

		# number of languages with f2 = j
		Nj = 0
		try
			Nj = tetra[join(["0", j])] + tetra[join(["1", j])]
		catch
		end

		# total number of languages in contingency table
		N = sum(values(tetra))

		# number of languages of type t
		X = 0
		try
			X = tetra[join(t)]
		catch
		end

		# probability of fewer than X languages of type t = [i,j]
		dis = Hypergeometric(Ni, N - Ni, Nj)
		pval_bot = sum([pdf(dis, y) for y in 0:X])

		# probability of more than X languages of type t = [i,j]
		pval_top = sum([pdf(dis, y) for y in X:N])

		if pval_bot < alpha
			push!(ua, join(t))
		end

		if pval_top < alpha
			push!(oa, join(t))
		end

		if !(pval_bot < alpha) && !(pval_top < alpha)
			push!(ne, join(t))
		end
	end

	Dict(:underattested => ua,
	     :overattested => oa,
	     :neither => ne)
end


# make one simulation
#
# N: number of languages
# d: number of neighbours for each language
# iter: how long to run simulation for
#
function simulate(; N, d, iter, vert_prob, v_rates1, v_rates2, h_rates)
	# model properties
	#
	# interpretation:
	#
	# vert_prob is the probability of a vertical event; 1 - vert_prob is then
	# the probability of a horizontal event
	#
	# v_rates is a tuple of two matrices. The first one gives the vertical
	# flipping probabilities for feature 1, the second gives them for feature 2.
	# Interpretation: cell A[i,j] of such a matrix A gives the probability
	# that the feature, currently in state i, flips its state, given that
	# the other feature is in state j.
	#
	# h_rates gives the horizontal probabilities. Interpretation: cell A[i,j]
	# of this matrix gives the probability that a horizontal event occurs
	# (i.e. horizontal flipping is attempted): the neighbour language attempts
	# to send fi = j to the focal language (there is no flip if focal language's
	# fi is already in state j; otherwise there will be a flip).
	#
	props = Dict(:vert_prob => vert_prob,
		     :v_rates => (v_rates1, v_rates2),
		     :h_rates => h_rates)


	# model space
	g = erdos_renyi(N, N*d)
	space = GraphSpace(g)


	# define model
	model = StandardABM(Language,
			    space,
			    agent_step! = mystep!,
			    properties = props)


	# add agents
	for i in 1:length(vertices(g))
		add_agent_single!(model, rand(0:1, 2))
	end


	# run simulation
	data, _ = run!(model, iter; adata=[:f], when=[iter])
	subset!(data, :time => t -> t .== iter)


	# attestations
	atts = attestations(data)


	# neighbourhood entropies
	H_under = NE(atts[:underattested]; model=model, data=data)
	H_over = NE(atts[:overattested]; model=model, data=data)
	H = NE(["00", "01", "10", "11"]; model=model, data=data)
	Delta_under = H_under - H
	Delta_over = H_over - H


	# return
	return Dict(:data => data,
		    :model => model,
		    :tetrachoric => get_tetrachoric(data, prop=true),
		    :attestations => atts,
		    :Delta_under => Delta_under,
		    :Delta_over => Delta_over)
end

























