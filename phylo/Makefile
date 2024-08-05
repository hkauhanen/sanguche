J=julia +1.5.3


.PHONY : all prep data mrbayes revbayes posterior pps purge

all : data mrbayes revbayes posterior pps

prep :
	mkdir $(DATASET)

data : 
	rm -rf $(DATASET)/data
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes : 
	cd $(DATASET)/code; $J runMrBayes.jl

revbayes :
	cd $(DATASET)/code/; sh rb.sh

posterior :
	cd $(DATASET)/code; Rscript createPosterior.r

pps :
	cd $(DATASET)/code; $J priorPredictiveSampling.jl

purge :
	rm -rf wals
	rm -rf grambank


