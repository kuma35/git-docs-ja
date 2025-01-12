#!/usr/bin/awk
# protect-opt-dash.sed, and SYNOPSIS's [verse] to [synopsis]
# protect-opt-dash.sed:
# ^-hoge::$ and ^--hoge::$ to `-hoge`:: and `--hoge`::
#
# SYNOPSIS's [verse] to [synopsis] :
# SYNOPSIS
# --------
# [verse]
# →
# SYNOPSIS
# --------
# [synopsis]
#
/^SYNOPSIS$/ {
    synopsis_title = $0;
    getline;
    if ($0 ~ /^[-]+$/) {
	separator = $0;
	getline;
	if ($0 ~ /^\[verse\]$/) {
	    print synopsis_title
	    print separator
	    print "[synopsis]"
	} else {
	    print synopsis_title
	    print separator
	    print $0
	}
    } else {
	print synopsis_title
    }
    next
}

/^(--?.+)::$/ {
    # s/^\(--\?.\+\)::$/`\1`::/
    print "`" $1 "`"
    next
}

{ print }
