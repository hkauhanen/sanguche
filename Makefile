J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROC=2


.PHONY : revise data sand phylodata

revise :
	cp -R src/code $(DATASET)

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)
	cd $(DATASET)/code; $J preprocess_$(DATASET).jl
	cd $(DATASET)/code; $J createData.jl $(DATASET)

sand : 
	cd $(DATASET)/code; $(JNEW) make_dicts.jl $(DATASET)
	cd $(DATASET)/code; $(JNEW) -p $(NPROC) sandwichness_km.jl

phylodata : 
	cd $(DATASET)/code; $J createPhyloData.jl $(DATASET)


