JULIA=julia +1.10.4
JOPTS=--project=.
J=$(JULIA) $(JOPTS)
R=Rscript
NPROCS=16


.PHONY : preparations analysis posthoc deps preprocess data dicts sand pretty Jdeps Rdeps merge stats plots clean purge

deps : Jdeps Rdeps

preparations : preprocess data

analysis : preprocess data dicts sand pretty

posthoc : merge plots stats

clean :
	rm -rf tmp/$(DATASET)

purge :
	rm -rf tmp
	rm -rf results

Jdeps : jl/deps.jl
	cd jl; $J deps.jl

preprocess : tmp/$(DATASET)/codes.csv tmp/$(DATASET)/languages.csv tmp/$(DATASET)/parameters.csv tmp/$(DATASET)/values.csv

data : tmp/$(DATASET)/data.jls

dicts : tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls

sand : tmp/$(DATASET)/sand_results.jls

pretty : results/$(DATASET)/results.jls results/$(DATASET)/results.csv

Rdeps : R/Rdeps.R
	cd R; $R Rdeps.R

merge : results/combined.RData
	
results/combined.RData : phylo4/src/postprocess/combine.jl R/merge.R results/wals/results.jls results/grambank/results.jls
	cd phylo4/src/postprocess; $(JULIA) combine.jl wals; $(JULIA) combine.jl grambank
	cd R; $R merge.R

plots : results/plots/boxplot.png results/plots/distances.png results/plots/neighbourhood_dispref.png results/plots/kdiff.png
	
results/plots/boxplot.png results/plots/distances.png results/plots/neighbourhood_dispref.png results/plots/kdiff.png &: results/combined.RData R/plots.R R/kvsk.R
	cd R; $R plots.R

stats : results/tables/stats.txt

results/tables/stats.txt : results/combined.RData R/stats.R
	cd R; $R stats.R

tmp/$(DATASET)/codes.csv tmp/$(DATASET)/languages.csv tmp/$(DATASET)/parameters.csv tmp/$(DATASET)/values.csv &: jl/preprocess_$(DATASET).jl
	cd jl; $J preprocess_$(DATASET).jl

tmp/$(DATASET)/data.jls : jl/make_data.jl jl/params.jl tmp/$(DATASET)/codes.csv tmp/$(DATASET)/languages.csv tmp/$(DATASET)/values.csv
	cd jl; $J make_data.jl $(DATASET)

tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls &: jl/make_dicts.jl jl/params.jl tmp/$(DATASET)/data.jls
	cd jl; $J make_dicts.jl $(DATASET)

tmp/$(DATASET)/sand_results.jls : jl/sandwichness.jl tmp/$(DATASET)/grid.jls tmp/$(DATASET)/Ddata.jls tmp/$(DATASET)/Ddists.jls
	cd jl; $J -p $(NPROCS) sandwichness.jl $(DATASET)

results/$(DATASET)/results.jls results/$(DATASET)/results.csv &: jl/prettyprint.jl tmp/$(DATASET)/sand_results.jls
	cd jl; $J prettyprint.jl $(DATASET)
