#!/bin/sh
find ./ -not \( -path './howto/*' -o -path './technical/*' -o -path './RelNotes/*' \) -name "*.po" | xargs grep -c  -P '`(?:[^` ]+(?:[][<>]|\s)+){1,}[^` ]+`' | sort | gawk 'BEGIN{FS=":"; print "# -*- mode: org -*-"; print "# please see gen-enclose-back-tick-list.sh"; print "# toggle todo C-c C-t"} $2>0 { print "* TODO " $1 "\t" $2}'
