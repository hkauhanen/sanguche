#!/usr/bin/bash

make purge DATASET=$1
make data DATASET=$1
make mrbayes_small DATASET=$1
make mrbayes_large DATASET=$1
make revbayes DATASET=$1
make posterior DATASET=$1
make model DATASET=$1
make correlations DATASET=$1
