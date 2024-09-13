J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript
NPROCS=8


.PHONY : log purge data purge_mrbayes mrbayes_large mrbayes_problematic mrbayes_rest revbayes posterior model correlations

log :
	Rscript logvisuals.R
	date > log.txt
	echo "==================================================================" >> log.txt
	bash mrbayes_progress.sh >> log.txt
	echo "==================================================================" >> log.txt
	/home/hkauhanen/.local/bin/gpustat >> log.txt
	echo "==================================================================" >> log.txt
	sensors | grep Tctl >> log.txt

purge :
	rm -rf $(DATASET)

purge_mrbayes :
	rm -rf $(DATASET)/data/asjpNex/output/*
	rm -rf $(DATASET)/code/mrbayes/converged/*
	rm -rf $(DATASET)/code/mrbayes/logs/*
	rm -rf $(DATASET)/code/mrbayes/*

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl
	cd $(DATASET)/code; $J createFmList.jl

mrbayes_large : 
	cd $(DATASET)/code; $J -p 3 runMrBayes.jl fm_large.txt

mrbayes_problematic : 
	cd $(DATASET)/code; $J -p 1 runMrBayes.jl fm_problematic.txt

mrbayes_rest : 
	cd $(DATASET)/code; $J -p 5 runMrBayes.jl fm_rest.txt

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROCS) runrevbayes.jl

posterior :
	cd $(DATASET)/code; $R createPosterior.r

model :
	cd $(DATASET)/code; bash model.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

