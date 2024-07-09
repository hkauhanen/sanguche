J=julia
PROCS=4
DEGREE=10


.PHONY : all data dicts sand pretty clean cleanall

all : data dicts sand pretty

clean :
	rm -rf tmp

cleanall :
	rm -rf tmp
	rm -rf results

data : tmp/$(DATASET)/data.jls

dicts : tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls

sand : tmp/$(DATASET)/sand_results.jls

pretty : results/$(DATASET)/results.jls results/$(DATASET)/results.csv

tmp/$(DATASET)/data.jls : jl/make_data_$(DATASET).jl jl/features_$(DATASET).jl
	cd jl; $J make_data_$(DATASET).jl

tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls &: jl/make_dicts.jl jl/features_$(DATASET).jl tmp/$(DATASET)/data.jls
	cd jl; $J make_dicts.jl $(DATASET) $(DEGREE)

tmp/$(DATASET)/sand_results.jls : jl/sandwichness.jl tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls
	cd jl; $J -p $(PROCS) sandwichness.jl $(DATASET)

results/$(DATASET)/results.jls results/$(DATASET)/results.csv &: jl/prettyprint.jl tmp/$(DATASET)/sand_results.jls
	cd jl; $J prettyprint.jl $(DATASET)
