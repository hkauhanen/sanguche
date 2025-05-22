J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
#DICTSCRIPT=make_dicts.jl
DICTSCRIPT=make_dicts_neoattestation_better.jl
MRBSCRIPT=runMrBayes_strict.jl


.PHONY : Jdeps preprocess data dicts sandwich phyloprep familyprep revbayes treelog posterior model correlations postprocess stats plots


Jdeps :
	cd src/code; $J deps_JW.jl
	cd src/code; $(JNEW) deps.jl

preprocess : $(DATASET)/data/database/*.csv 

data : $(DATASET)/data/data.csv

$(DATASET)/data/database/*.csv : src/code/preprocess_$(DATASET).jl src/code/params.jl
	cd src/code; $J preprocess_$(DATASET).jl

$(DATASET)/data/data.csv : src/code/createData.jl src/code/params.jl $(DATASET)/data/database/*.csv
	cd src/code; $J createData.jl $(DATASET)

dicts : $(DATASET)/dicts/Ddata.jls $(DATASET)/dicts/Ddists.jls $(DATASET)/dicts/grid.jls $(DATASET)/dists.csv

$(DATASET)/dicts/Ddata.jls $(DATASET)/dicts/Ddists.jls $(DATASET)/dicts/grid.jls $(DATASET)/dists.csv &: src/code/$(DICTSCRIPT) src/code/params.jl src/code/deps.jl $(DATASET)/data/data.csv
	cd src/code; $(JNEW) $(DICTSCRIPT) $(DATASET) $(LIMTYPE)

sandwich : results/$(DATASET)/sand_results.csv results/$(DATASET)/sand_results.jls

results/$(DATASET)/sand_results.csv results/$(DATASET)/sand_results.jls &: src/code/sandwichness.jl src/code/params.jl src/code/deps.jl $(DATASET)/dicts/Ddata.jls $(DATASET)/dicts/Ddists.jls $(DATASET)/dicts/grid.jls
	cd src/code; $(JNEW) -p $(NPROC) sandwichness.jl $(DATASET) $(LIMTYPE)

phyloprep : src/code/createPhyloData.jl src/code/params.jl $(DATASET)/data/data.csv $(DATASET)/data/database/*.csv
	cd src/code; $J createPhyloData.jl $(DATASET)

familyprep : src/code/createFmList.jl src/code/family_stats.R src/code/fm_large_$(DATASET).txt src/code/fm_problematic_$(DATASET).txt
	cd src/code; $J createFmList.jl $(DATASET)
	cd src/code; $R family_stats.R $(DATASET)

revbayes : src/code/runrevbayes.jl
	cd src/code; $J -p $(NPROC) runrevbayes.jl $(DATASET)

mrbayes : src/code/$(MRBSCRIPT) src/code/fm_large_$(DATASET).txt src/code/fm_problematic_$(DATASET).txt src/code/fm_rest_$(DATASET).txt
	cd src/code; $J -p 3 $(MRBSCRIPT) $(DATASET) fm_large_$(DATASET).txt & $J -p 1 $(MRBSCRIPT) $(DATASET) fm_problematic_$(DATASET).txt & $J -p 12 $(MRBSCRIPT) $(DATASET) fm_rest_$(DATASET).txt; wait

purge_mrbayes :
	rm -rf $(DATASET)/data/asjpNex/output/$(FAMILY).*
	rm -rf $(DATASET)/mrbayes/converged/$(FAMILY).*
	rm -rf $(DATASET)/mrbayes/logs/$(FAMILY).*
	rm -rf $(DATASET)/mrbayes/$(FAMILY).*

treelog : src/code/logvisuals.R
	cd src/code; $R logvisuals.R $(DATASET)

posterior : src/code/createPosterior.r
	cd src/code; $R createPosterior.r $(DATASET)

model : src/code/models.sh src/code/model_1.sh src/code/model_2.sh src/code/model_3.sh src/code/model_4.sh src/code/model_5.sh src/code/modelFitting/universal.jl src/code/modelFitting/loadData.jl
	cd src/code; bash models.sh $(DATASET)

correlations : results/$(DATASET)/correlations.csv results/$(DATASET)/bfCorr.csv
	
results/$(DATASET)/correlations.csv results/$(DATASET)/bfCorr.csv &: src/code/correlations.jl src/code/savage_dickey.R
	cd src/code; $J correlations.jl $(DATASET)

postprocess : results/$(DATASET)/results_combined.csv
	
results/$(DATASET)/results_combined.csv : src/code/postprocess.jl results/$(DATASET)/correlations.csv results/$(DATASET)/bfCorr.csv results/$(DATASET)/sand_results.csv
	cd src/code; $(JNEW) postprocess.jl $(DATASET)

stats : results/stats_$(DATASET).html

results/stats_$(DATASET).html : src/stats/stats.Rmd results/$(DATASET)/results_combined.csv
	cd src/stats; $R runstats.R $(DATASET)

plots : results/plots/*.png

results/plots/*.png : src/stats/plots.R src/stats/kloop.R results/$(DATASET)/results_combined.csv
	cd src/stats; $R plots.R $(DATASET) $(LIMTYPE)
