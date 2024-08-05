J=julia +1.5.3
NPROC_MRBAYES=8
NPROC_REVBAYES=16


.PHONY : all data mrbayes revbayes posterior pps purge

all : data mrbayes revbayes posterior pps

data : 
	rm -rf $(DATASET)
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes : 
	cd $(DATASET)/code; $J --project=. -p $(NPROC_MRBAYES) runMrBayes.jl

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROC_REVBAYES) runrevbayes.jl

posterior :
	cd $(DATASET)/code; Rscript createPosterior.r

pps :
	cd $(DATASET)/code; $J priorPredictiveSampling.jl

purge :
	rm -rf wals
	rm -rf grambank


