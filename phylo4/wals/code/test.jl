using Distributed

@everywhere cd(@__DIR__)


dataset = ARGS[1]

if length(ARGS) > 1
  @everywhere function argfunc(args)
    return args
  end

  @everywhere println(args)
end


