#!/usr/bin/bash

CONV=`ls $1/code/mrbayes/converged/*.txt -lh | wc -l`

TOTL=`cat $1/data/glot3.txt | wc -l`

echo "Families converged: $CONV / $TOTL"


