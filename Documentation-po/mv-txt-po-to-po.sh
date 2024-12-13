#!/bin/sh
# cd Documentation-po
# find ./ -name "*.po" -exec ./mv-txt-po-to-po.sh {} \;
SRC=$1
DST=${SRC%.po}
DST=${DST%.txt}
DST=${DST}.po
git mv ${SRC} ${DST}

