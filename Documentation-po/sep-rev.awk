#
# hideo@winston:~/work/git-docs-ja/Documentation-po/RelNotes
# $ ls -l | gawk ../sep-rev.awk | clip
{
    split($9, rev, ".")
    print rev[1],rev[2],rev[3],$9
}
