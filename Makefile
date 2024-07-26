JULIA=julia
JOPTS=--project=.
J=$(JULIA) $(JOPTS)
PROCS=2
DEGREE=10


.PHONY : analysis deps data dicts sand pretty plots clean purge

analysis : deps data dicts sand pretty

clean :
	rm -rf tmp

purge :
	rm -rf tmp
	rm -rf results

deps : jl/deps.jl
	cd jl; $J deps.jl

data : deps tmp/$(DATASET)/data.jls

dicts : deps tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls

sand : deps tmp/$(DATASET)/sand_results.jls

pretty : deps results/$(DATASET)/results.jls results/$(DATASET)/results.csv

plots : deps results/wals/results.jls results/grambank/results.jls jl/plots.jl
	cd jl; $J plots.jl

tmp/$(DATASET)/data.jls : jl/make_data_$(DATASET).jl jl/features_$(DATASET).jl
	cd jl; $J make_data_$(DATASET).jl

tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls &: jl/make_dicts.jl jl/features_$(DATASET).jl tmp/$(DATASET)/data.jls
	cd jl; $J make_dicts.jl $(DATASET) $(DEGREE)

tmp/$(DATASET)/sand_results.jls : jl/sandwichness.jl tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls
	cd jl; $J -p $(PROCS) sandwichness.jl $(DATASET)

results/$(DATASET)/results.jls results/$(DATASET)/results.csv &: jl/prettyprint.jl tmp/$(DATASET)/sand_results.jls
	cd jl; $J prettyprint.jl $(DATASET)
