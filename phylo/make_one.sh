#!/usr/bin/bash

#make data DATASET=$1           # runtime: some minutes
#make revbayes DATASET=$1       # runtime: some minutes, times 2 or 3
make mrbayes_small DATASET=$1   # runtime: some hours!!!
#make mrbayes_large DATASET=$1  # runtime: some DAYS!!!
#make posterior DATASET=$1      # runtime: some minutes
#make model DATASET=$1          # runtime: some hours
#make correlations DATASET=$1   # runtime: some minutes
