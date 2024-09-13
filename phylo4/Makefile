J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROCS=8


.PHONY : purge data purge_mrbayes mrbayes revbayes posterior model correlations

purge :
	rm -rf $(DATASET)

purge_mrbayes :
	rm -rf $(DATASET)/data/asjpNex/output/*
	rm -rf $(DATASET)/code/mrbayes/converged/*
	rm -rf $(DATASET)/code/mrbayes/logs/*

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes : 
	cd $(DATASET)/code; $J -p $(NPROCS) runMrBayes.jl $(DATASET)

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROCS) runrevbayes.jl

posterior :
	cd $(DATASET)/code; $R createPosterior.r

model :
	cd $(DATASET)/code; bash model.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

