#!/bin/bash
pushd ${HOME}/work/git-docs-ja/Documentation-po/
ls -1 *.po howto/*.po technical/*.po config/*.po | awk -f po_stat.awk
date
popd
