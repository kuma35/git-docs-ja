# po_count
BEGIN {
    SUM_TRANSLATED = 0
    SUM_FUZZY = 0
    SUM_UNTRANSLATED = 0
    FILE_COUNT=0
}
{
    # 21 translated messages, 1 fuzzy translation, 16 untranslated messages.
    translated = 0
    fuzzy = 0
    untranslated = 0
    # print $0
    # msgfmt -v --statistics to stderr !! 
    "LANG=C msgfmt -v --statistics " $0 " 2>&1" | getline line
    # print "line=" line
    if (match(line, /([0-9]+)[ ]translated/, a)) {
	translated = a[1]
	SUM_TRANSLATED += a[1]
    }
    if (match(line, /([0-9]+)[ ]fuzzy/, b)) {
	fuzzy = b[1]
	SUM_FUZZY += b[1] 
    }
    if (match(line, /([0-9]+)[ ]untranslated/, c)) {
	untranslated = c[1]
	SUM_UNTRANSLATED += c[1]
    }
    if (translated == 0 && fuzzy == 0 && untranslated == 0 ) {
	print $0 ": NOT MATCH"
    }
    FILE_COUNT++
}

END {
    # print "filecount=" filecount
    # print SUM_TRANS
    # print SUM_FUZZY
    # print SUM_UNTRANS
    print "files: " FILE_COUNT
    # printf("total: %d translated messages, %d fuzzy translation, %d untranslated messages.\n", SUM_TRANSLATED, SUM_FUZZY, SUM_UNTRANSLATED)
    printf("total: %d+%df+%du\n", SUM_TRANSLATED, SUM_FUZZY, SUM_UNTRANSLATED)
    printf("progress: %3.2f%%\n", (SUM_TRANSLATED / (SUM_FUZZY + SUM_UNTRANSLATED))*100)
}
