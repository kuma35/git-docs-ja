#!/bin/sh
# in sh,bash, ture is 0(zero), false is non-zero
git ls-files -m -- "*.po4cfg" | while read line; do
    if test -e ${line} &&
	    git diff --quiet -I"^# generate by.*[ 0-9]+年[ 0-9]+月[ 0-9]+日" HEAD -- ${line} &&
	    ! git diff --quiet HEAD -- ${line}
    then
	git restore --source HEAD -- ${line}
    fi
done
