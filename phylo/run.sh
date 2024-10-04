#!/usr/bin/bash

make data DATASET=wals & make data DATASET=grambank

wait

make revbayes DATASET=wals NPROCS=16
make revbayes DATASET=grambank NPROCS=16

#make mrbayes_large DATASET=$1 NPROCS=3 & make mrbayes_rest DATASET=$1 NPROCS=12
make mrbayes_rest DATASET=wals NPROCS=4 \
  & make mrbayes_rest DATASET=grambank NPROCS=4 \
  & make mrbayes_large DATASET=wals NPROCS=3 \
  & make mrbayes_large DATASET=grambank NPROCS=3

wait

make posterior DATASET=wals
make posterior DATASET=grambank

make model DATASET=wals
make model DATASET=grambank

wait

make correlations DATASET=wals
make correlations DATASET=grambank
