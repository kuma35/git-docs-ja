#!/bin/sh
# cd Documentation-po
# find ./ -name "*.po" -exec ./mv-txt-po.sh {} \;
SRC=$1
DST=${SRC%.po}.txt.po
git mv ${SRC} ${DST}

