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
    git -C $repo_dir add $zuul_d/project.yaml
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
    else
        echo "Editing $repo_dir/$zuul_yaml"
        python3 $bindir/add_job.py $repo_dir/$zuul_yaml
    fi

    git -C $repo_dir add $zuul_yaml
}

function update_zuul {
    local repo_dir=$1
    local repo_type=$(get_repo_type $repo_dir)

    case "$repo_type" in
        .zuul.d|zuul.d)
            update_zuul_d $repo_dir $repo_type;;
        zuul.yaml|.zuul.yaml)
            update_zuul_yaml $repo_dir $repo_type;;
        unknown)
            update_zuul_yaml $repo_dir .zuul.yaml;;
    esac
}

function update_tox_ini {
    local repo_dir=$1
    local ini_file=$repo_dir/tox.ini

    if grep -q 'testenv:lower-constraints' $ini_file;
    then
        echo "No need to update $ini_file"
        return
    fi

    cat - >> $ini_file <<EOF

[testenv:lower-constraints]
basepython = python3
deps =
  -c{toxinidir}/lower-constraints.txt
  -r{toxinidir}/test-requirements.txt
  -r{toxinidir}/requirements.txt
EOF
    git -C $repo_dir add tox.ini
}

function create_lower_constraints {
    local repo_dir=$1

    rm -f $repo_dir/lower-constraints.txt
    cp $repo_root/requirements/lower-constraints.txt $repo_dir/lower-constraints.txt
    (cd $repo_dir &&
        tox -e lower-constraints --notest -r &&
        .tox/lower-constraints/bin/pip freeze | grep -v git.openstack.org > lower-constraints.txt
    )
    git -C $repo_dir add lower-constraints.txt
}

function commit {
    local repo_dir=$1

    (cd $repo_dir && git commit -F $bindir/commit_message.txt)
}

set -e

for bf in $batchfiles;
do
    for repo in $(cat $bf);
    do
        repo_dir=$repo_root/$repo
        echo
        echo $repo_dir

        update_zuul $repo_dir
        update_tox_ini $repo_dir
        create_lower_constraints $repo_dir

        commit $repo_dir
    done
done
