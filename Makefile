JULIA=julia +1.10.4
JOPTS=--project=.
J=$(JULIA) $(JOPTS)
R=Rscript
NPROCS=4


.PHONY : preparations analysis posthoc deps preprocess data dicts sand pretty Jdeps Rdeps distances merge stats plots clean purge

deps : Jdeps Rdeps

preparations : preprocess data

analysis : dicts sand pretty

posthoc : merge plots stats

clean :
	rm -rf tmp/$(DATASET)*

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

distances : merge tmp/wals/neighbour_distances.csv tmp/grambank/neighbour_distances.csv

tmp/wals/neighbour_distances.csv tmp/grambank/neighbour_distances.csv &: jl/neighbour_distances.jl tmp/wals/Ddists.jls tmp/grambank/Ddists.jls
	cd jl; $J neighbour_distances.jl wals
	cd jl; $J neighbour_distances.jl grambank

merge : results/combined.RData results/featuretables/featuretable_withDelta_wals.csv results/featuretables/featuretable_withDelta_grambank.csv

results/featuretables/featuretable_withDelta_wals.csv results/featuretables/featuretable_withDelta_grambank.csv &: R/featuretables.R
	cd R; $R featuretables.R
	
results/combined.RData : phylo/src/postprocess/combine.jl R/merge.R results/wals/results.jls results/grambank/results.jls
	cd phylo/src/postprocess; $(JULIA) combine.jl wals; $(JULIA) combine.jl grambank
	cd R; $R merge.R

plots : results/plots/boxplot.png results/plots/distances.png results/plots/neighbourhood_dispref.png results/plots/kdiff.png
	
results/plots/boxplot.png results/plots/distances.png results/plots/neighbourhood_dispref.png results/plots/kdiff.png &: results/combined.RData R/plots.R R/load_data.R tmp/wals/Ddists.jls tmp/grambank/Ddists.jls
	cd R; $R plots.R

stats : results/tables/stats.pdf

results/tables/stats.pdf : results/combined.RData R/stats.R R/stats.Rmd R/load_data.R
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
