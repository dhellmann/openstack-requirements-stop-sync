#!/bin/bash

reporoot=$(dirname $(dirname $(realpath $0)))

batchfiles=$@

for bf in $batchfiles;
do
    for repo in $(cat $bf);
    do
        ls -d $reporoot/$repo
    done
done
