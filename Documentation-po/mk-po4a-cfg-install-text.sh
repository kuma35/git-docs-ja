#!/usr/bin/sh
# for only ../INSTALL
# mk-po4a-cfg.sh <<src-pathfile(relative)>>
SRC_FILE=$1
BASE_FILE=${SRC_FILE#../}
DST_FILE=../Documentation-ja/${BASE_FILE}.txt
BASE_BODY=${BASE_FILE}
echo "# generate by $0" `date`
echo "[po4a_langs] ja"
echo "[type: text] ${SRC_FILE} \$lang:${DST_FILE}"
echo "[po4a_paths] pot/${BASE_BODY}.pot ja:${BASE_BODY}.po"
