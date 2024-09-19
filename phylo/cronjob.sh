#!/usr/bin/bash
#

make log DATASET=grambank
git add ..
git commit -m 'update from office'
git push
