J=julia +1.5.3
JNEW=julia +1.10.4
R=Rscript


.PHONY : log purge data purge_mrbayes mrbayes_large mrbayes_problematic mrbayes_rest revbayes posterior model correlations

log :
	cd $(DATASET)/code; Rscript logvisuals.R $(DATASET)
	date > log_$(DATASET).txt
	echo "==================================================================" >> log_$(DATASET).txt
	bash mrbayes_progress.sh $(DATASET) >> log_$(DATASET).txt
	echo "==================================================================" >> log_$(DATASET).txt
	/home/hkauhanen/.local/bin/gpustat >> log_$(DATASET).txt
	echo "==================================================================" >> log_$(DATASET).txt
	sensors | grep Tctl >> log_$(DATASET).txt

purge :
	rm -rf $(DATASET)
	rm -rf results/$(DATASET)

purge_mrbayes :
	rm -rf $(DATASET)/data/asjpNex/output/$(FAMILY).*
	rm -rf $(DATASET)/code/mrbayes/converged/$(FAMILY).*
	rm -rf $(DATASET)/code/mrbayes/logs/$(FAMILY).*
	rm -rf $(DATASET)/code/mrbayes/$(FAMILY).*

data : 
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl
	cd $(DATASET)/code; $J createFmList.jl $(DATASET)

mrbayes_large : 
	cd $(DATASET)/code; $J -p $(NPROCS) runMrBayes.jl fm_large_$(DATASET).txt

mrbayes_problematic : 
	cd $(DATASET)/code; $J -p $(NPROCS) runMrBayes.jl fm_problematic_$(DATASET).txt

mrbayes_rest : 
	cd $(DATASET)/code; $J -p $(NPROCS) runMrBayes.jl fm_rest_$(DATASET).txt

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROCS) runrevbayes.jl

posterior :
	rm -rf $(DATASET)/data/posteriorTrees
	cd $(DATASET)/code; $R createPosterior.r

model :
	rm -rf $(DATASET)/code/modelFitting/output
	cd $(DATASET)/code; bash model_1.sh & bash model_2.sh & bash model_3.sh
	cd $(DATASET)/code; bash model_4.sh & bash model_5.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

