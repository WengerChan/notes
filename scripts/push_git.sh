#! /usr/bin/env bash

WORKSPACE='/Users/chenwen/Documents/workspace'

if [ -z "$1" ]; then
    echo -e "\033[1;31mError!\033[0m Please Specify [DIR]! "
    echo -e "<DIR>: <axzq|happy_ever_after|jwkj|...>"
    exit 1
else
    echo -e "\033[1;32mSyncing\033[0m [$1]"
    dir_name=$1
fi

if [ -z $2 ]; then
    remote="origin"
else
    remote=$2
fi

pushd $WORKSPACE/${dir_name}
git add .
git commit -m "Update $(date +'%Y%m%d')"
git push ${remote}
popd