#!/usr/bin/gawk -f
# git-command-list-todo
# git help -a | sed -En '/^\s+/s/^\s*(\S+).*$/\1/p'| sort
BEGIN {
    print "# Git commands SYNOPSIS to LITERAL TODO"
    print ""
}
{
    print "* TODO " $_
}
