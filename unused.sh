#!/bin/bash

bindir=$(dirname $(realpath $0))
repo_root=$(dirname $bindir)

for repo_dir in $(ls -d ../[0-9][0-9]/*);
do
    repo=$(basename $repo_dir)
    if ! grep -q $repo all.txt;
    then
        echo $repo_dir
        rm -rf $repo_dir
    fi
done
