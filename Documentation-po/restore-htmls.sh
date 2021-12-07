#!/bin/sh
# in sh,bash, ture is 0(zero), false is non-zero
git ls-files -m | while read line; do
    if test -e ${line} &&
	    git diff --quiet -I"^ [12][0-9][0-9][0-9]-[01][0-9]-[0123][0-9] [012][0-9]:[0-5][0-9]:[0-5][0-9] JST" -- ${line} &&
	    ! git diff --quiet -- ${line}
    then
	git restore -- ${line}
    fi
done
