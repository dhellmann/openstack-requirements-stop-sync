#!/bin/bash

bindir=$(dirname $(realpath $0))
repo_root=$(dirname $bindir)

source venv/bin/activate

batchfiles=$@

function get_repo_type {
    local repo_dir=$1

    if [ -e $repo_dir/.zuul.d ] ; then
        echo ".zuul.d"
    elif [ -e $repo_dir/zuul.d ] ; then
        echo "zuul.d"
    elif [ -e $repo_dir/.zuul.yaml ] ; then
        echo ".zuul.yaml"
    elif [ -e $repo_dir/zuul.yaml ] ; then
        echo "zuul.yaml"
    else
        echo "unknown"
    fi
}

function update_zuul_d {
    local repo_dir=$1
    local zuul_d=$2

    echo "Editing $repo_dir/$zuul_d/project.yaml"
    python3 $bindir/add_job.py $repo_dir/$zuul_d/project.yaml
}

function update_zuul_yaml {
    local repo_dir=$1
    local zuul_yaml=$2


    if [[ ! -e $repo_dir/$zuul_yaml ]]; then
        echo "Creating $repo_dir/$zuul_yaml"
        cat - > $repo_dir/$zuul_yaml <<EOF
- project:
    check:
      jobs:
        - openstack-tox-lower-constraints
    gate:
      jobs:
        - openstack-tox-lower-constraints
EOF
        return
    fi
    echo "Editing $repo_dir/$zuul_yaml"
    python3 $bindir/add_job.py $repo_dir/$zuul_yaml
}

for bf in $batchfiles;
do
    for repo in $(cat $bf);
    do
        repo_dir=$repo_root/$repo
        echo
        echo $repo_dir
        repo_type=$(get_repo_type $repo_dir)

        case "$repo_type" in
            .zuul.d|zuul.d)
                update_zuul_d $repo_dir $repo_type;;
            zuul.yaml|.zuul.yaml)
                update_zuul_yaml $repo_dir $repo_type;;
            unknown)
                update_zuul_yaml $repo_dir .zuul.yaml;;
        esac
    done
done
