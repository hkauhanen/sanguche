#!/usr/bin/bash

#make data DATASET=$1
make mrbayes_large DATASET=$1 NPROCS=3 & make mrbayes_problematic DATASET=$1 NPROCS=3 & make mrbayes_rest DATASET=$1 NPROCS=8
#make revbayes DATASET=$1 NPROCS=16
#make posterior DATASET=$1
#make model DATASET=$1
#sleep 1h   # make sure model has finished for all feature pairs before proceeding to correlations
#make correlations DATASET=$1
