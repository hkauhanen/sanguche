#!/usr/bin/bash
#

Rscript logvisuals.R
date > cron.log
bash mrbayes_progress.sh >> cron.log
/home/hkauhanen/.local/bin/gpustat >> cron.log
sensors >> cron.log
git add ..
git commit -m 'update from office'
git push
