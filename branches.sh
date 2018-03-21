#!/bin/bash

repo_root=$(dirname $(dirname $(realpath $0)))

for d in $(cat todo/*); do
    (cd $repo_root/$d; git checkout -b requirements-stop-syncing)
done
