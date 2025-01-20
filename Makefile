J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROC=16


.PHONY : Jdeps preprocess data dicts sandwich phyloprep familyprep revbayes treelog


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

$(DATASET)/dicts/*.jls : src/code/make_dicts.jl src/code/params.jl src/code/deps.jl $(DATASET)/data/data.csv
	cd src/code; $(JNEW) make_dicts.jl $(DATASET)

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
	cd src/code; $J -p 3 runMrBayes.jl $(DATASET) fm_large_$(DATASET).txt & $J -p 1 runMrBayes.jl $(DATASET) fm_problematic_$(DATASET).txt & $J -p 12 runMrBayes.jl $(DATASET) fm_rest_$(DATASET).txt

purge_mrbayes :
	rm -rf $(DATASET)/data/asjpNex/output/$(FAMILY).*
	rm -rf $(DATASET)/mrbayes/converged/$(FAMILY).*
	rm -rf $(DATASET)/mrbayes/logs/$(FAMILY).*
	rm -rf $(DATASET)/mrbayes/$(FAMILY).*

treelog : src/code/logvisuals.R
	cd src/code; $R logvisuals.R $(DATASET)
