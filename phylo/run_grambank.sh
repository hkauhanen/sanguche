#!/usr/bin/bash

#make data DATASET=grambank

#wait

make revbayes DATASET=grambank NPROCS=8

wait

make mrbayes_rest DATASET=grambank NPROCS=9 \
  & make mrbayes_large DATASET=grambank NPROCS=3

wait

make posterior DATASET=grambank

make model DATASET=grambank

wait

make correlations DATASET=grambank
