#!/bin/sh
# in sh,bash, ture is 0(zero), false is non-zero
git ls-files -m -- "*.html" | while read line; do
    if test -e ${line} &&
	    git diff --quiet -I"^ [12][0-9][0-9][0-9]-[01][0-9]-[0123][0-9] [012][0-9]:[0-5][0-9]:[0-5][0-9] JST" -I"^<span id=\"revdate\">[12][0-9][0-9][0-9]-[01][0-9]-[0123][0-9]</span>" HEAD -- ${line} &&
	    ! git diff --quiet HEAD -- ${line}
    then
	git restore --source HEAD -- ${line}
    fi
done
