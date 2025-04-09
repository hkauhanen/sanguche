J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROC=16
DICTS=make_dicts.jl
#DICTS=make_dicts_neoattestation.jl


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

dicts : $(DATASET)/dicts/*.jls

$(DATASET)/dicts/*.jls : src/code/$(DICTS) src/code/params.jl src/code/deps.jl $(DATASET)/data/data.csv
	cd src/code; $(JNEW) $(DICTS) $(DATASET)

sandwich : $(DATASET)/results/sand_results.csv $(DATASET)/results/sand_results.jls

$(DATASET)/results/sand_results.csv $(DATASET)/results/sand_results.jls &: src/code/sandwichness_km.jl src/code/params.jl src/code/deps.jl $(DATASET)/dicts/*.jls
	cd src/code; $(JNEW) -p $(NPROC) sandwichness_km.jl $(DATASET)

phyloprep : src/code/createPhyloData.jl src/code/params.jl $(DATASET)/data/data.csv $(DATASET)/data/database/*.csv
	cd src/code; $J createPhyloData.jl $(DATASET)

familyprep : src/code/createFmList.jl src/code/family_stats.R src/code/fm_large_$(DATASET).txt src/code/fm_problematic_$(DATASET).txt
	cd src/code; $J createFmList.jl $(DATASET)
	cd src/code; $R family_stats.R $(DATASET)

revbayes : src/code/runrevbayes.jl
	cd src/code; $J -p $(NPROC) runrevbayes.jl $(DATASET)

mrbayes : src/code/runMrBayes.jl src/code/fm_large_$(DATASET).txt src/code/fm_problematic_$(DATASET).txt src/code/fm_rest_$(DATASET).txt
	cd src/code; $J -p 3 runMrBayes.jl $(DATASET) fm_large_$(DATASET).txt & $J -p 1 runMrBayes.jl $(DATASET) fm_problematic_$(DATASET).txt & $J -p 12 runMrBayes.jl $(DATASET) fm_rest_$(DATASET).txt; wait

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
	cd src/stats; $R plots.R $(DATASET)
