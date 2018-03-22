#!/bin/bash

bindir=$(dirname $(realpath $0))
repo_root=$(dirname $bindir)

source venv/bin/activate

# We could take $* or $@ here but the workflow is really to do one
# batch at a time so there's not much point and by doing it this way
# we can use * on the command line so we don't have to keep modifying
# the command we run.
batchfiles=$1

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
        sleep 10
    done

    $bindir/promote.sh $bf
done
