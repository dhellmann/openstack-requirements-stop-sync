#!/bin/bash

repo_root=$(dirname $(dirname $(realpath $0)))

batchfiles=$@

function get_repo_type {
    local repo_dir=$1

    if [ -e $repo_dir/.zuul.d ] ; then
        echo ".zuul.d"
    elif [ -e $repo_dir/zuul.d ] ; then
        echo "zuul.d"
    elif [ -e $repo_dir/.zuul.yaml ] ; then
        echo ".zuul.yaml"
    else
        echo "unknown"
    fi
}

function update_zuul_d {
    local repo_dir=$1
    local zuul_d=$2

    if [[ ! -d $repo_dir/$zuul_d ]]; then
        echo "Creating $repo_dir/$zuul_d"
        mkdir $repo_dir/$zuul_d
    fi

    if [[ ! -e $repo_dir/$zuul_d/project.yaml ]]; then
        echo "Creating $repo_dir/$zuul_d/project.yaml"
        cat - > $repo_dir/$zuul_d/project.yaml <<EOF
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

    if grep -q openstack-tox-lower-constraints $repo_dir/$zuul_d/project.yaml;
    then
        echo "No need to update $repo_dir/$zuul_d/project.yaml"
        return
    fi

    echo "DO NOT KNOW HOW TO EDIT EXISTING PROJECT FILE"
}

function update_zuul_yaml {
    local repo_dir=$1
    echo "DO NOT KNOW HOW TO EDIT EXISTING YAML FILE"
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
            unknown)
                update_zuul_d $repo_dir zuul.d;;
            .zuul.yaml)
                update_zuul_yaml $repo_dir;;
        esac
    done
done
