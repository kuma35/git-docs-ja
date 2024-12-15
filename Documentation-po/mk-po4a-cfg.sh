#!/usr/bin/sh
# mk-po4a-cfg.sh <<src-pathfile(relative)>>
SRC_FILE=$1
BASE_FILE=${SRC_FILE#../Documentation-sedout/}
DST_FILE=../Documentation-ja/${BASE_FILE}
BASE_BODY=${BASE_FILE%.txt}
echo "# generate by $0" `date`
echo "[po4a_langs] ja"
echo "[type: asciidoc] ${SRC_FILE} \$lang:${DST_FILE}"
echo "[po4a_paths] pot/${BASE_BODY}.pot ja:${BASE_BODY}.po"
