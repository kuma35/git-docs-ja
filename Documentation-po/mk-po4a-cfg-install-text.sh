#!/usr/bin/sh
# for only ../INSTALL text
# mk-po4a-cfg.sh <<src-pathfile(relative)>> <<dst-pathfile(relative)>>
SRC_FILE=$1
BASE_FILE=${SRC_FILE#../}
DST_FILE=$2
BASE_BODY=${BASE_FILE}
echo "# generate by $0" `date`
echo "[po4a_langs] ja"
echo "[type: text] ${SRC_FILE} \$lang:${DST_FILE}"
echo "[po4a_paths] pot/${BASE_BODY}.pot ja:${BASE_BODY}.po"
