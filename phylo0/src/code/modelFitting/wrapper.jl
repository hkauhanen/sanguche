using Distributed

@everywhere cd(@__DIR__)
@everywhere using Pkg
@everywhere Pkg.activate("..")
@everywhere Pkg.instantiate()

##
@everywhere using LinearAlgebra, StatsBase, CSV, DataFrames, Pipe, ProgressMeter, Random, Glob


##

@everywhere using MCPhylo
@everywhere Random.seed!(4928370335238343681)



##

@everywhere wals = CSV.read("../../data/charMtx.csv", DataFrame)
@everywhere d = CSV.read("../../data/fpairMtx.csv", DataFrame)

@everywhere famFreqs = combine(groupby(wals, :glot_fam), nrow)
@everywhere sort!(famFreqs, :nrow, rev=true)

@everywhere families = filter(x -> x.nrow>1, famFreqs).glot_fam
@everywhere isolates = filter(x -> x.nrow==1, famFreqs).glot_fam



##### Restrict analysis to those families only for which posterior trees actually exist
@everywhere postfam = glob("*.posterior.tree", "../../data/posteriorTrees")
@everywhere postfam = [split(fam)[1] for fam in postfam]
@everywhere families = families[families .∈ [postfam]]


@everywhere isoDict = @pipe wals |>
      filter(x -> x.glot_fam ∈ isolates, _) |>
      zip(_.glot_fam, _.longname) |>
      Dict
##


@everywhere fm2trees = Dict()
#@everywhere @showprogress for fm in families
for fm in families
      @everywhere fm2trees[$fm] = MCPhylo.ParseNewick("../../data/posteriorTrees/$fm.posterior.tree")
end

for fm in isolates
      @everywhere fm2trees[$fm] = repeat([Node(isoDict[$fm])], 1000)
end

##


@everywhere function renumberTree(tree::GeneralNode)
      tips = [nd for nd in post_order(tree) if nd.nchild==0]
      nonTips = [nd for nd in post_order(tree) if nd.nchild > 0]
      sort!(tips, lt= (x,y) -> x.name < y.name)
      for (i,nd) in enumerate(tips)
            nd.num = i
      end
      for (i,nd) in enumerate(nonTips)
            nd.num = i+length(tips)
      end
      tree
end

##

for fm in keys(fm2trees)
      @everywhere fm2trees[$fm] = renumberTree.(fm2trees[$fm])
end

##

@everywhere lineages = vcat(families, isolates)

##

@everywhere ttrees = [[fm2trees[fm][i] for fm in lineages] for i in 1:1000]



##

@everywhere states = ["a", "b", "c", "d"]

@everywhere nsites = 1

@everywhere nbase = 4

@everywhere rates = [1.0]

##
@everywhere taxa = Vector{String}[]
for t in ttrees[1]
      @everywhere push!(taxa, sort([nd.name for nd in pre_order($t) if nd.nchild==0]))
end

##










@everywhere function universal(charNum::Int)
  ##

  char = @pipe d |>
  zip(_[:, :taxon], _[:, charNum+1]) |>
  Dict
  ##



  nnodes = [length(post_order(t)) for t in ttrees[1]]


  data = zeros(nbase, nsites, maximum(nnodes), length(ttrees[1]))

  for i in 1:length(taxa)
    for l in taxa[i]
      s = char[l]
      t_ind = find_by_name(ttrees[1][i],l).num
      if s in states
        data[:,1,t_ind, i] = (states .== s)
      else
        data[:,1,t_ind, i] .= 1
      end
    end
  end

  ##


  nLineages = length(lineages)


  my_data = Dict{Symbol, Any}(
                              :data => data,
                              :nLineages => nLineages
                             )

  ##
  model = Model(
    ind = Stochastic(0, () -> Logistic(), true),
    data = Stochastic(
                      4,
                      (fullSrates, nLineages, ind) -> MultiplePhyloDist(
                                                                        ttrees[Integer(ceil(1000 * invlogit(ind[])))],
                                                                        fullSrates,
                                                                        ones(1, nLineages),
                                                                        freeK,
                                                                       ),
                      false,
                     ),
    s_rates = Stochastic(1, () -> Normal(0, 1), true),
    fullSrates = Logical(
                         2,
                         (s_rates, nLineages) -> begin
                           x = exp.(s_rates)
                           reshape(repeat(x, nLineages), (12, nLineages))
                         end,
                         false,
                        ),
  )

  ##


  inits = [Dict{Symbol, Any}(
                             :data => data,
                             :nLineages => nLineages,
                             :s_rates => rand(Normal(0,1), 12),
                             :ind => (a = zeros(); a[]=rand(Logistic()); a),
                            ) for i in 1:2]

  ##



  scheme = [Slice(:s_rates, 1.), Empirical(:ind, 1) ]

  setsamplers!(model, scheme)

  ##

  try
    mkdir("output")
  catch e
  end

  ##

  sim = mcmc(
    model,
    my_data,
    inits,
    20000,
    burnin = 0,
    thin = 5,
    chains = 2,
    trees = false,
  )
  bi = 1 + size(sim)[1] ÷ 2
  gd = gelmandiag(sim[bi:end,:,:])
  psrf = maximum(gd.value[:,1])
  write("output/universal_$(lpad((charNum), 2, "0")).jls", sim[bi:end,:,:])
  write("output/universal_$(lpad((charNum), 2, "0")).log", string(psrf)*"\n")
  while psrf > 1.1
    global sim, psrf, bi, gd
    @show psrf
    sim = mcmc(sim, 1000)
    bi = 1 + size(sim)[1] ÷ 2
    gd = gelmandiag(sim[bi:end,:,:])
    psrf = maximum(gd.value[:,1])
    write("output/universal_$(lpad((charNum), 2, "0")).jls", sim[bi:end,:,:])
    write("output/universal_$(lpad((charNum), 2, "0")).log", string(psrf)*"\n")
  end

end


@sync @distributed for i in 1:45
  universal(i)
end
