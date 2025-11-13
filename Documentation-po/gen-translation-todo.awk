# -*- mode: awk -*-
# cd git-docs-ja/Documentation-po
# ( ./msgstat.sh newbie; ./msgstat.sh) | gawk -f gen-translation-todo.awk
BEGIN {
    BREAK_COUNT=0
    print "# -*- mode: org -*-";
    print "# please see gen-translation-todo.awk";
    print "# toggle todo C-c C-t"
}

$1 !~ /[0-9]+\+[0-9]+f\+[0-9]+u/ {
    print "# " $0
    next
}

{
    print "* TODO " $0
    BREAK_COUNT = BREAK_COUNT + 1
    if (BREAK_COUNT < 10) {  # 10 po files(0...9)
	# nothing
    } else {
	print "# save point. git push for github page."
	BREAK_COUNT = 0
    }
}
