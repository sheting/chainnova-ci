#!/bin/bash

echo '*********'
echo '*** [CHECKING GIT STATUS] ***'
echo '*********'

git status | grep -E -q "nothing to commit.*\s+clean"
if [[ $? == 0 ]]; then
    echo 'SUCCESS!'
    exit 0
else
    echo "!!!Error: working directory is not clean."
    git status
    exit 1
fi