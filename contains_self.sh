#!/bin/bash

bindir=$(dirname $(realpath $0))
repo_root=$(dirname $bindir)

source venv/bin/activate

for repo in $(cat $bindir/all.txt);
do
    cd $repo_root/*/$repo
    name=$(python setup.py --name 2>/dev/null)
    if grep -q "^${name}=" lower-constraints.txt;
    then
        contains=YES
    else
        contains=NO
    fi
    batch=$(basename $(grep -n "^$repo\$" $bindir/local/* $bindir/submitted/* | cut -f1 -d:))
    echo "$repo  $batch  $contains"
done
