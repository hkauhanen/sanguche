#no_feature_pairs = 45
no_feature_pairs = 2

using Pkg
Pkg.activate("..")
Pkg.instantiate()

using Distributed
using Glob

@everywhere include("loadData.jl")
@everywhere include("universal.jl")

@sync @distributed for i in 1:no_feature_pairs
  do_analysis(i)
end

