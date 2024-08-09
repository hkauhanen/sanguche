J=julia +1.5.3
NPROC_MRBAYES=8
NPROC_REVBAYES=16


.PHONY : all data mrbayes revbayes posterior model purge

all : data mrbayes revbayes posterior model

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

model :
	cd $(DATASET)/code/modelFitting; $J --project=.. -p 2 fitmodel.jl

purge :
	rm -rf wals
	rm -rf grambank


