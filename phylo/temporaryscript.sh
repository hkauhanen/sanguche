make mrbayes DATASET=wals
make posterior DATASET=wals
make model DATASET=wals
make correlations DATASET=wals

git add ..
git commit -m 'newest phylo results for WALS'
git push



make mrbayes DATASET=grambank
make posterior DATASET=grambank
make model DATASET=grambank
make correlations DATASET=grambank

git add ..
git commit -m 'newest phylo results for Grambank'
git push


