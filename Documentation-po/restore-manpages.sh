#!/bin/sh
# in sh,bash, ture is 0(zero), false is non-zero
git ls-files -m -- "*.1" "*.5" "*.7" | while read line; do
    if test -e ${line} &&
	    git diff --quiet -I"\.TH .*" -I".\\\"    Source: .*" HEAD -- ${line} &&
	    ! git diff --quiet HEAD -- ${line}
    then
	git restore --source HEAD -- ${line}
    fi
done
