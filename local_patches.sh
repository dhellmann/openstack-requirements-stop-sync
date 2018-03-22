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

function create_project_file {
    local outfile=$1

    echo "Creating $outfile"
    cat - > $outfile <<EOF
- project:
    check:
      jobs:
        - openstack-tox-lower-constraints
    gate:
      jobs:
        - openstack-tox-lower-constraints
EOF
}

function update_zuul_d {
    local repo_dir=$1
    local zuul_d=$2

    if grep -q -- "- project:" $repo_dir/$zuul_d/job.yaml;
    then
        local to_update=$repo_dir/$zuul_d/job.yaml
    elif grep -q -- "- project:" $repo_dir/$zuul_d/jobs.yaml;
    then
        local to_update=$repo_dir/$zuul_d/jobs.yaml
    else
        local to_update=$repo_dir/$zuul_d/project.yaml
    fi

    if [[ ! -e $to_update ]]; then
        create_project_file $to_update
    else
        echo "Editing $to_update"
        python3 $bindir/add_job.py $to_update
    fi

    git -C $repo_dir add $to_update
}

function update_zuul_yaml {
    local repo_dir=$1
    local zuul_yaml=$2

    if [[ ! -e $repo_dir/$zuul_yaml ]]; then
        create_project_file $repo_dir/$zuul_yaml
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

    reqfile=""
    if [[ -f "$repo_dir/requirements.txt" ]]; then
        reqfile="  -r{toxinidir}/requirements.txt"
    else
        echo "No requirements.txt, leaving out of tox.ini"
    fi

    cat - >> $ini_file <<EOF

[testenv:lower-constraints]
basepython = python3
deps =
  -c{toxinidir}/lower-constraints.txt
  -r{toxinidir}/test-requirements.txt
$reqfile
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

function clone {
    local name
    local localdir
    local longname
    local url

    for name in "$@"
    do
        if [[ ! $name =~ / ]]; then
            longname=$(ssh review.openstack.org -p 29418 gerrit ls-projects \
                | grep "/$name\$")
            if [[ -z "$longname" ]]; then
                # This is not an OpenStack repository.  Look at the
                # local caches for github and bitbucket.
                longname=$(ls -d $OS_REPO_DIR/*/$name)
                if [[ -d $longname ]]; then
                    echo "Cloning $name from $longname"
                    git clone $longname
                    url=$(cd $longname && git config --get remote.origin.url)
                    (cd $name && \
                            git remote set-url origin "$url")
                    url=$(cd $longname && git config --get remote.dhellmann.url)
                    if [[ ! -z "$url" ]]; then
                        (cd $name && \
                                git remote add dhellmann "$url" && \
                                git remote update dhellmann)
                    fi
                    (cd $name && \
                            git fetch --tags origin && \
                            git checkout master && \
                            git hooks --install)
                    return $?
                else
                    echo "Could not find $name in $OS_REPO_DIR"
                    return 1
                fi
            fi
        else
            longname="$name"
            name=$(basename $name)
        fi
        if [[ -d $name ]]; then
            echo "$name already exists"
            continue
        fi
        ~/tools/zuul/bin/zuul-cloner \
            --branch master \
            git://git.openstack.org \
            $longname
        (cd "$longname" && \
            git fetch --tags origin && \
            git checkout master && \
            git hooks --install && \
            git review -s)
        mv $longname $name
        rmdir $(dirname $longname) || echo "Could not remove $(dirname $longname)"
    done
}


function clone_repo {
    local repo=$1
    local outdir=$2

    if [[ -d $outdir ]]; then
        echo "Local clone already exists"
        return
    fi
    echo "Cloning $repo"
    local pardir=$(dirname $outdir)
    mkdir -p $pardir
    (cd $pardir && clone $repo)
    git -C $outdir checkout -b requirements-stop-syncing
}

set -e

for bf in $batchfiles;
do
    bf_dir=$repo_root/$(basename $bf)
    mkdir -p $bf_dir
    for repo in $(cat $bf);
    do
        repo_dir=$bf_dir/$repo
        echo
        echo $repo_dir

        clone_repo $repo $repo_dir
        update_zuul $repo_dir
        update_tox_ini $repo_dir
        create_lower_constraints $repo_dir

        commit $repo_dir
    done
done
