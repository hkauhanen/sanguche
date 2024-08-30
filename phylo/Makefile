J=julia +1.5.3
JNEW=julia +1.10.4
NPROCS=16
#NPROCS_MODEL=16


.PHONY : purge data mrbayes_wals mrbayes_grambank revbayes posterior model correlations

purge :
	rm -rf $(DATASET)

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes_wals : 
	cd $(DATASET)/code; $J -p 15 runMrBayes.jl $(DATASET)

mrbayes_grambank : 
	cd $(DATASET)/code; $J -p 1 runMrBayes.jl $(DATASET)

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROCS) runrevbayes.jl

posterior :
	cd $(DATASET)/code; Rscript createPosterior.r

model :
	#cd $(DATASET)/code/modelFitting; $J -p $(NPROCS_MODEL) wrapper.jl
	cd $(DATASET)/code; bash fitmodel.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

