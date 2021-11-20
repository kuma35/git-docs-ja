#!/bin/bash
pushd ${HOME}/work/git-docs-ja/Documentation-po/
# find ./ -not -path "./RelNotes/*" -type f -name "*.po" -print | gawk -f ./po_count.awk
ls -1 *.po howto/*.po technical/*.po config/*.po | gawk -f ./po_count.awk
popd
