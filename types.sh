#!/bin/bash

REPO_BASE=$(dirname $(dirname $(realpath $0)))

for repo in $(cat all.txt); do
    if [ -e $REPO_BASE/$repo/.zuul.d ] ; then
        echo $repo .zuul.d
    fi
    if [ -e $REPO_BASE/$repo/zuul.d ] ; then
        echo $repo zuul.d
    fi
    if [ -e $REPO_BASE/$repo/.zuul.yaml ] ; then
        echo $repo .zuul.yaml
    fi
done
