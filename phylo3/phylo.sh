#!/usr/bin/bash
bash make_one.sh wals & bash make_one.sh grambank
make model DATASET=wals
make model DATASET=grambank
make correlations DATASET=wals & make correlations DATASET=grambank
