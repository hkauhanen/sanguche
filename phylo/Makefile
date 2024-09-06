J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROCS=8


.PHONY : purge data mrbayes_small mrbayes_large revbayes posterior model correlations

purge :
	rm -rf $(DATASET)

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes_small : 
	cd $(DATASET)/code; $J runMrBayes.jl $(DATASET) small $(RESID)

mrbayes_large : 
	cd $(DATASET)/code; $J runMrBayes.jl $(DATASET) large $(RESID)

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROCS) runrevbayes.jl

posterior :
	cd $(DATASET)/code; $R createPosterior.r

model :
	cd $(DATASET)/code; bash model.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

