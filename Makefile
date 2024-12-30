J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROC=2


.PHONY : Jdeps preprocess data dicts sandwich phyloprep


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


