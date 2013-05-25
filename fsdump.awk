#!/usr/bin/awk -f
#
# dumpfs -- performs a dump of each filesystem listed by "dump w" in an
#           odd/even rotation scheme: 0,3,4,7,8,1,2,5,6,9,0
#
#           Tested on OpenBSD 5.2 and 5.3

BEGIN {

    dumpdir   = "/data/fsdump"
    ext       = "gz"
    listfs    = "dump w"
    getdate   = "date \"+%Y%m%d\""
    mntcmd    = "mount -u -o"
    fsckcmd   = "fsck -fy"

    sub(/\/+$/,"",dumpdir)

    getdate | getline date ; close(getdate)

    # learn mount options from fstab
    while ((getline < "/etc/fstab") > 0)
    {
        mntopts[$2] = $4
    }
    close("/etc/fstab")

    while ((listfs | getline) > 0)
    {
        remount = 0

        # skip first line of dump's output
        if (!lno) { lno++ ; continue }
        gsub(/[ \t\\(\\),>]+/," ")

        if (!root && $2 == "/")
        {
            fs = "root" # found the root fs
            root++
        }
        else
        {
            # this isn't the root (/) filesystem, so try to
            # remount it in read-only and force an fsck
            fs = $2 ; sub(/^\//,"",fs) ; sub(/\//,"_",fs)
            mntargs = ( "ro " $2 " >/dev/null 2>&1" )

            if (system(mntcmd mntargs) == 0)
            {
                remount = 1
                print "Filesystem remounted as rdonly:", $2
                print "Running fsck:", $2
                system(fsckcmd " " $2) ; close(fsckcmd " " $2)
            }
            close(mntcmd mntargs)
            mntargs = ""
        }

        # last dump:  next dump:
        # ---------   ---------
        (($6 == 9) && $6 = 0) ||
        (($6 == 8) && $6 = 1) ||
        (($6 == 7) && $6 = 8) ||
        (($6 == 6) && $6 = 9) ||
        (($6 == 5) && $6 = 6) ||
        (($6 == 4) && $6 = 7) ||
        (($6 == 3) && $6 = 4) ||
        (($6 == 2) && $6 = 5) ||
        (($6 == 1) && $6 = 2) ||
        (($6 == 0) && $6 = 3)

        outfile = (dumpdir "/" date "-" fs "." $6 "." ext)
        do_dump = ("dump " $6 "auf - " $1 " | gzip -9 > " outfile)

        # perform the dump
        print "Dumping filesystem:", $2
        system(do_dump) ; close(do_dump)

        # mount the filesystem with options from fstab
        if ( remount == 1 && $2 in mntopts )
        {
            print "Remounting", $2, "with options:", mntopts[$2]
            system(mntcmd mntopts[$2] " " $2)
            close(mntcmd mntopts[$2] " " $2)
        }
        print "Dump completed for:", $2
    }
    close(listfs)
}
