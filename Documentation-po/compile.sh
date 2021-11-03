#!/bin/sh
cd ${HOME}/work/git-docs-ja/Documentation-sedout
for dst_dir in technical RelNotes config howto
do
    if [ ! -d ${dst_dir} ]; then
	mkdir ${dst_dir}
    fi
done
cd ${HOME}/work/git-docs-ja/Documentation-po
make ja
cd ${HOME}/work/git-docs-ja/Documentation-ja
make info $*
GIT_INFO="git.info"
GITMAN_INFO="gitman.info"
INFO_DIR="dir"
if [ -e ${GIT_INFO} ]; then
    install-info ${GIT_INFO} ${INFO_DIR}
fi
if [ -e ${GITMAN_INFO} ]; then
    install-info ${GITMAN_INFO} ${INFO_DIR}
fi
