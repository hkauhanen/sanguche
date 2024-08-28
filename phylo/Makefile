J=julia +1.5.3
JNEW=julia +1.10.4
NPROCS=8
#NPROCS_MODEL=16


.PHONY : purge data mrbayes_small mrbayes_large revbayes posterior model correlations

purge :
	rm -rf $(DATASET)

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes_small : 
	cd $(DATASET)/code; $J -p $(NPROCS) runMrBayes.jl $(DATASET) small

mrbayes_large : 
	cd $(DATASET)/code; $J -p $(NPROCS) runMrBayes.jl $(DATASET) large

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROCS) runrevbayes.jl

posterior :
	cd $(DATASET)/code; Rscript createPosterior.r

model :
	#cd $(DATASET)/code/modelFitting; $J -p $(NPROCS_MODEL) wrapper.jl
	cd $(DATASET)/code; bash fitmodel.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

