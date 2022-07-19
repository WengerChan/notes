#! /usr/bin/env bash

WORKSPACE="/Users/chenwen/Documents/workspace"

if [ -z $1 ]; then
    git_repo="axzq notes happy_ever_after jwkj set_yum_reposity Demographic_Prediction_Based_on_Scikit_Learn"
else
    git_repo=$1
fi
echo -e "Pulling from github.com...\033[60G\033[5;32mSyncing\033[0m"

num=1
for repo in $(echo ${git_repo}); do
    cd $WORKSPACE/${repo}
    branch_name=$(git branch | head -n 1 | awk '{print $NF}')
    echo -e -n "Pull ${num}. ${repo}:origin/${branch_name}\033[60G\033[5;33mSyncing\033[0m"
 
    # git pull origin ${branch_name} &>/dev/null
    [ $? -eq 0 ] && status="32m[OK]" || status="31m[ERROR]"
    echo -e "\033[7D\033[K\033[${status}\033[0m"
    let num+=1
done

[ $? -eq 0 ] && echo -e "\033[${num}A\033[60G\033[K\033[32m[Completed!]\033[0m\033[$((num-1))B" \
             || echo -e "\033[${num}A\033[60G\033[K\033[31m[Error!]\033[0m\033[$((num-1))B"