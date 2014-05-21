#!/usr/bin/awk -f
#
# fsdump.awk -- performs a dump of each filesystem listed by "dump w" in an
#               odd/even rotation scheme: 0,3,4,7,8,1,2,5,6,9,0
#
#               Tested on OpenBSD 5.2 and 5.3

function nextlevel(lastlvl)
{
    if (lastlvl == 0) return 3
    if (lastlvl == 1) return 2
    if (lastlvl == 2) return 5
    if (lastlvl == 3) return 4
    if (lastlvl == 4) return 7
    if (lastlvl == 5) return 6
    if (lastlvl == 6) return 9
    if (lastlvl == 7) return 8
    if (lastlvl == 8) return 1
    if (lastlvl == 9) return 0
}

BEGIN \
{
    dumpdir   = "/data/fsdump"
    ext       = "gz"
    listfs    = "dump w"
    getdate   = "date \"+%Y%m%d\""
    mntcmd    = "mount -u -o"
    fsckcmd   = "fsck -fy"

    sub(/\/+$/, "", dumpdir)

    getdate | getline date
    close(getdate)

    # Learn each filesystem's mount options from fstab
    while ((getline < "/etc/fstab") > 0)
        mntopts[$2] = $4

    close("/etc/fstab")

    while ((listfs | getline) > 0)
    {
        remount = 0

        # Jump the first line of dump's output and make the rest easier
        # to parse
        if (!lno)
        {
            lno++
            continue
        }

        gsub(/[ \t\\(\\),>]+/, " ")

        # Non-root filesystems are remounted read-only and checked with fsck
        if (!root && $2 == "/")
        {
            fs = "root"
            root++
        }
        else
        {
            fs = $2
            sub(/^\//,"", fs)
            sub(/\//,"_", fs)

            mntargs = ( "ro " $2 " >/dev/null 2>&1" )

            if (system(mntcmd mntargs) == 0)
            {
                remount = 1
                print "Filesystem remounted as rdonly:", $2
                print "Running fsck:", $2
                system(fsckcmd " " $2)
                close(fsckcmd " " $2)
            }
            close(mntcmd mntargs)
            mntargs = ""
        }

        lvl = nextlevel($6)

        outfile = (dumpdir "/" date "-" fs "." lvl "." ext)
        do_dump = ("dump " lvl "auf - -h0 " $1 " | gzip -9 > " outfile)

        # Dump and remount the filesystem
        print "Dumping filesystem:", $2
        system(do_dump)
        close(do_dump)

        if (remount == 1 && $2 in mntopts)
        {
            print "Remounting", $2, "with options:", mntopts[$2]
            system(mntcmd mntopts[$2] " " $2)
            close(mntcmd mntopts[$2] " " $2)
        }
        print "Dump completed for:", $2
    }
    close(listfs)
}
