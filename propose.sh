#!/bin/bash

bindir=$(dirname $(realpath $0))
repo_root=$(dirname $bindir)

source venv/bin/activate

batchfiles=$@

set -e

for bf in $batchfiles;
do
    bf_dir=$repo_root/$(basename $bf)
    for repo in $(cat $bf);
    do
        repo_dir=$bf_dir/$repo
        echo
        echo $repo_dir

        git -C $repo_dir review
    done
done
