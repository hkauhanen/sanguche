using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Distributed
using Glob

@everywhere cd("revbayes")

@sync @distributed for fm in glob("*.Rev", ".")
  command = `rb $fm`
  run(command)
end

