#!/usr/bin/bash

#make purge DATASET=$1           # runtime: negligible
#make data DATASET=$1            # runtime: some minutes
#make revbayes DATASET=$1        # runtime: some minutes, times 2 or 3
make mrbayes_$1 DATASET=$1        # runtime: some days!!!
#make posterior DATASET=$1      # runtime: some minutes
#make model DATASET=$1          # runtime: ???
#make correlations DATASET=$1   # runtime: some minutes
