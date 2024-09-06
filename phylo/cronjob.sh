#!/usr/bin/bash
#

date > cron.log
bash mrbayes_progress.sh >> cron.log
git add ..
git commit -m 'update from office'
git push
