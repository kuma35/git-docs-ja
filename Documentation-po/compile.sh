#!/bin/sh
PROJ=${HOME}/work/git-docs-ja
cd ${PROJ}/Documentation-sedout
for dst_dir in technical RelNotes config howto
do
    if [ ! -d ${dst_dir} ]; then
	mkdir ${dst_dir}
    fi
done
cd ${PROJ}/Documentation-po
make ja
exitcode=$?
if [ ${exitcode} -ne 0 ]; then
    notify-send -u critical git-docs-ja "Documentation-po/Makefile エラー"
    exit ${exitcode}
fi
cd ${PROJ}/Documentation-ja
make info $*
exitcode=$?
if [ ${exitcode} -ne 0 ]; then
    notify-send -u critical git-docs-ja "Documentation-ja/Makefile エラー"
    exit ${exitcode}
fi
#
GIT_INFO="git.info"
GITMAN_INFO="gitman.info"
INFO_DIR="dir"
if [ -e ${GIT_INFO} ]; then
    install-info ${GIT_INFO} ${INFO_DIR}
fi
if [ -e ${GITMAN_INFO} ]; then
    install-info ${GITMAN_INFO} ${INFO_DIR}
fi
# for github pages
cp -v *.info ${PROJ}/docs/info
cp -v dir ${PROJ}/docs/info
DIFF=diff ${PROJ}/Documentation-ja/install-webdoc.sh ${PROJ}/docs/htmldocs
#
notify-send -u normal git-docs-ja "compile完了。"

