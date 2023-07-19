#!/bin/sh
PROJ=${HOME}/work/git-docs-ja
cd ${PROJ}/Documentation-sedout
for dst_dir in technical RelNotes config howto includes mergetools
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
# gen file "dir" for info. and publish to docs/info/
make -f ${PROJ}/Documentation-po/publish-info.mak
exitcode=$?
if [ ${exitcode} -ne 0 ]; then
    notify-send -u critical git-docs-ja "publish-info.mak エラー"
    exit ${exitcode}
fi
# restore htmls and manpaese in Documentation-ja
${PROJ}/Documentation-po/restore-htmls.sh
${PROJ}/Documentation-po/restore-manpages.sh
# for github pages
DIFF=diff ${PROJ}/Documentation-po/install-webdoc-only-html.sh ${PROJ}/docs/htmldocs
gawk -f ${PROJ}/Documentation-po/publish-index.awk TEMPLATE=${PROJ}/Documentation-po/index.html.template OUTPUT=${PROJ}/docs/index.html < ${PROJ}/../git/GIT-VERSION-FILE
exitcode=$?
if [ ${exitcode} -ne 0 ]; then
    notify-send -u critical git-docs-ja "publish-index.awk エラー"
    exit ${exitcode}
fi
# restore htmls in docs
cd ${PROJ}/docs
${PROJ}/Documentation-po/restore-htmls.sh
#
notify-send -u normal git-docs-ja "compile完了。"

