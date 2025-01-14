using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Distributed
using Glob

@everywhere myargfunc(x) = x
@everywhere dataset = myargfunc($ARGS)[1]

@everywhere cd("../../$dataset/revbayes")

@sync @distributed for fm in glob("*.Rev", ".")
  command = `rb $fm`
  run(command)
end

