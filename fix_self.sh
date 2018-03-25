#!/bin/bash

set -ex

bindir=$(dirname $(realpath $0))
repo_root=$(dirname $bindir)

cat contains-self.txt | while read repo batch needs_fix;
do
    if [[ "$needs_fix" != "YES" ]]; then
        continue
    fi
    echo $repo $batch
    cd $repo_root/$batch/$repo
    name=$(python setup.py --name 2>/dev/null)
    sed -i -e "/^${name}\$/d" lower-constraints.txt
    git add lower-constraints.txt
    git commit --amend --no-edit
    if [[ -f $bindir/submitted/$batch ]];
    then
        git review
    fi
done
