#!/usr/bin/bash

make data DATASET=$1                          # runtime: some minutes
make revbayes DATASET=$1                      # runtime: some minutes, times 2 or 3
make mrbayes DATASET=$1                       # runtime: some DAYS (!)
make posterior DATASET=$1                     # runtime: some minutes
