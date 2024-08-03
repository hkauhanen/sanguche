#!/bin/sh

cd revbayes
for f in *Rev; do rb $f; done
cd ..
