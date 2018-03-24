#!/bin/bash

bindir=$(dirname $(realpath $0))

STAGES="todo local submitted"

for stage in $STAGES;
do
    echo "$stage $(cat $bindir/$stage/* 2>/dev/null | wc -l)"
done
