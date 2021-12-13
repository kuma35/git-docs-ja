# po_stat
# only list in-completed po files.
{
    # 21 translated messages, 1 fuzzy translation, 16 untranslated messages.
    translated = 0
    fuzzy = 0
    untranslated = 0
    # print $0
    # msgfmt -v --statistics to stderr !! 
    "LANG=C msgfmt -v --statistics --output-file=/dev/null " $0 " 2>&1" | getline line
    # print "line=" line
    if (match(line, /([0-9]+)[ ]translated/, a)) {
	translated = a[1]
    }
    if (match(line, /([0-9]+)[ ]fuzzy/, b)) {
	fuzzy = b[1]
    }
    if (match(line, /([0-9]+)[ ]untranslated/, c)) {
	untranslated = c[1]
    }
    if ((translated > 0) && (fuzzy != 0 || untranslated > 0 )) {
	print $0
    }
}
