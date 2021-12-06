#!/bin/sh
PROJ=${HOME}/work/git-docs-ja
git ls-files -m  | while read line; do
    # echo "${line}"
    # git diff  --quiet --ignore-cr-at-eol --ignore-space-at-eol --ignore-blank-lines -I"2021-" -- ${line}
    git diff --exit-code -- ${line}
    git diff --quiet -I"^ [12][0-9][0-9][0-9]-[01][0-9]-[0123][0-9] [012][0-9]:[0-5][0-9]:[0-5][0-9] JST" -- ${line}
    echo $? ${line}
done
