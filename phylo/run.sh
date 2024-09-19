#!/usr/bin/bash

#make data DATASET=$1
make mrbayes_large DATASET=$1 NPROCS=3 & make mrbayes_problematic DATASET=$1 NPROCS=3 & make mrbayes_rest DATASET=$1 NPROCS=8
#make revbayes DATASET=$1
#make posterior DATASET=$1
#make model DATASET=$1
#make correlations DATASET=$1
