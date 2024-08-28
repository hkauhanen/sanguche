J=julia +1.5.3
JNEW=julia +1.10.4
NPROC_MRBAYES=1
NPROC_REVBAYES=16
#NPROC_MODEL=16


.PHONY : all data mrbayes revbayes posterior model correlations

all : data revbayes mrbayes posterior model correlations

data : 
	rm -rf $(DATASET)
	mkdir $(DATASET)
	cp -R src/code $(DATASET)/code
	cd $(DATASET)/code; $J createData_$(DATASET).jl

mrbayes : 
	cd $(DATASET)/code; $J -p $(NPROC_MRBAYES) runMrBayes.jl $(DATASET)

revbayes :
	cd $(DATASET)/code/; $J --project=. -p $(NPROC_REVBAYES) runrevbayes.jl

posterior :
	cd $(DATASET)/code; Rscript createPosterior.r

model :
	#cd $(DATASET)/code/modelFitting; $J -p $(NPROC_MODEL) wrapper.jl
	cd $(DATASET)/code; bash fitmodel.sh

correlations :
	cd $(DATASET)/code; $J correlations.jl $(DATASET)

