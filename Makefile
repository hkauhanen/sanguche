JULIA=julia +1.10.4
JOPTS=--project=.
J=$(JULIA) $(JOPTS)
R=Rscript
NPROC=2


.PHONY : analysis deps preprocess data dicts sand pretty plots clean purge

analysis : deps preprocess data dicts sand pretty

clean :
	rm -rf tmp

purge :
	rm -rf tmp
	rm -rf results

deps : jl/deps.jl
	cd jl; $J deps.jl

preprocess : deps tmp/$(DATASET)/codes.csv tmp/$(DATASET)/languages.csv tmp/$(DATASET)/parameters.csv tmp/$(DATASET)/values.csv

data : deps tmp/$(DATASET)/data.jls

dicts : deps tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls

sand : deps tmp/$(DATASET)/sand_results.jls

pretty : deps results/$(DATASET)/results.jls results/$(DATASET)/results.csv

plots : results/wals/results.csv results/grambank/results.csv R/plots.R
	cd R; $R plots.R

tmp/$(DATASET)/codes.csv tmp/$(DATASET)/languages.csv tmp/$(DATASET)/parameters.csv tmp/$(DATASET)/values.csv &: jl/preprocess_$(DATASET).jl
	cd jl; $J preprocess_$(DATASET).jl

tmp/$(DATASET)/data.jls : jl/make_data.jl jl/params.jl tmp/$(DATASET)/codes.csv tmp/$(DATASET)/languages.csv tmp/$(DATASET)/values.csv
	cd jl; $J make_data.jl $(DATASET)

tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls &: jl/make_dicts.jl jl/params.jl tmp/$(DATASET)/data.jls
	cd jl; $J make_dicts.jl $(DATASET)

tmp/$(DATASET)/sand_results.jls : jl/sandwichness.jl tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls
	cd jl; $J -p $(NPROC) sandwichness.jl $(DATASET)

results/$(DATASET)/results.jls results/$(DATASET)/results.csv &: jl/prettyprint.jl tmp/$(DATASET)/sand_results.jls
	cd jl; $J prettyprint.jl $(DATASET)
