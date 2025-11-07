# Adapted from code by Gerhard Jäger & Johannes Wahle,
# https://github.com/gerhardJaeger/phylogeneticTypology,
# under the MIT licence (see LICENSE in root folder).


using Distributed

@everywhere using Pkg
@everywhere Pkg.activate("JW")
#@everywhere Pkg.instantiate()

@everywhere using Glob

@everywhere myargfunc(x) = x
@everywhere dataset = myargfunc($ARGS)[1]

@everywhere cd("../../$dataset/revbayes")

@sync @distributed for fm in glob("*.Rev", ".")
  command = `rb $fm`
  run(command)
end

