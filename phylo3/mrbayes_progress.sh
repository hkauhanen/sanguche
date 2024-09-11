#!/usr/bin/bash

WALS_CONV=`ls wals/code/mrbayes/converged/*.txt -lh | wc -l`
GRAM_CONV=`ls grambank/code/mrbayes/converged/*.txt -lh | wc -l`

WALS_TOTL=`cat wals/data/glot3.txt | wc -l`
GRAM_TOTL=`cat grambank/data/glot3.txt | wc -l`

echo "Families converged, WALS:     $WALS_CONV / $WALS_TOTL"
echo "Families converged, Grambank: $GRAM_CONV / $GRAM_TOTL"


