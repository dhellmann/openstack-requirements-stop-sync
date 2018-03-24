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
    state=$(basename $(dirname $bf))
    case $state in
        todo)
            next=local;;
        local)
            next=submitted;;
        *)
            echo "Do not know how to promote $bf";
            exit 1;;
    esac
    git -C $bindir mv $bf ${next}/
    git -C $bindir commit -m "promoted batch $(basename $bf)"
done

$bindir/counts.sh
