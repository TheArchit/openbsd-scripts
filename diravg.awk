#!/usr/local/bin/awk -f
#
#   diravg.awk  -- gathers file size statistics for a given tree
#
#   Usage: ./diravg.awk /path/to/tree
#
#   BUGS:
#           * won't handle directories with over eight spaces in their name,
#             colon or non-printing characters characters at then end
#
#   TODO:
#           * function to convert bytes to specified units
#           * repeat heading every getenv[LINES]
#           * allow spaces in names of directories passed via ARGV
#           * allow multiple directories to be passed via ARGV
#           * display stats for each directory passed via ARGV
#

function diravg(dir,    lno, dirc, fc, fmin, fzero, fnzero,
                fsum, fmax, name, i, regex)
{
    path = dir
    while (("ls -laR " dir | getline) > 0)
    {
        if ($0 ~ /^$/)
        {
            dirc = ""
            fc = ""
            fzero = ""
            fnzero = ""
            fmin = ""
            fmax = ""
            fsum = ""
            continue
        }

        if ($0 ~ /:$/)
        {
            sub(/:$/, "")
            path = $0
            continue
        }

        # skip over block and character devices, symlinks, pipes,
        # unix sockets and default unix dot directories
        if ($9 == "." || $9 == ".." || $1 ~ /^(l|b|c|p|s)/)
            continue

        if ($1 ~ /^-/)
        {
            fc++

            if ($5 == 0)
                fzero++
            else
                fnzero++

            if ($5 == 0 || $5 < fmin || fmin == "")
                fmin = $5

            if ($5 >= fmax)
                fmax = $5

            if (fnzero)
                fsum += $5
        }

        if ($1 ~ /^d/)
            dirc++

        arr[path] = ( dirc "," fc "," fzero "," fnzero "," fmin "," \
                        fmax "," fsum )
    }
    close("ls -laR " dir)
}

function countarr(arr,  i, c)
{
    for (i in arr)
        c++
    return c
}

BEGIN \
{
    diravg(ARGV[1]) # returns array 'arr'

#
#
#   func diravg -- creates 'arr' array object where the index specifies the
#                   directory name. The values are arranged as follows:
#
#                   dirc:   number of subdirectories
#                   fc:     number of files
#                   fz:     number of zero-byte files
#                   fnz:    number of non-empty files
#                   fmin:   size of smallest file in bytes
#                   fmax:   size of largest file in bytes
#                   fsum:   sum of all files in bytes
#
#   Array values can be split() using comma as the field delimiter.
#   Values can be null or a positive integer. Testing for null values can save
#   a lot of work, for example if val2 (num files) is null, there won't be any
#   available file statistics to display.
#

    fmt_dirc    = "%7s";    printf fmt_dirc,    "dirs:"
    fmt_fc      = "%7s";    printf fmt_fc,      "files:"
    fmt_fz      = "%7s";    printf fmt_fz,      "zero:"
    fmt_fnz     = "%7s";    printf fmt_fnz,     "nzero:"
    fmt_fmin    = "%10s";   printf fmt_fmin,    "fmin:"
    fmt_fmax    = "%10s";   printf fmt_fmax,    "fmax:"
    fmt_fsum    = "%10s";   printf fmt_fsum,    "fsum:"
    fmt_favg    = "%10s";   printf fmt_favg,    "favg:"
    fmt_dir     = " %s\n"

    printf fmt_dir, "path:"

    for (i in arr)
    {
        split(arr[i], row, ",")

        dir = i
        dirc = row[1]
        fc = row[2]
        fz = row[3]
        fnz = row[4]
        fmin = row[5]
        fmax = row[6]
        favg = fsum = row[7]

        # zero-byte files have no weight in our avg file size
        # calculation
        if (fnz != "")
            favg = sprintf("%d", (fsum / fnz))

        # per directory stats
        printf fmt_dirc, dirc   # dir count
        printf fmt_fc, fc       # file count
        printf fmt_fz, fz       # count of zero-byte files
        printf fmt_fnz, fnz     # count of files with data
        printf fmt_fmin, fmin   # smallest sized file
        printf fmt_fmax, fmax   # largest sized file
        printf fmt_fsum, fsum   # sum of all file sizes
        printf fmt_favg, favg   # average file size
        printf fmt_dir, dir     # directory path

        if (dirc == "")
        {
            if (fc == "")
                emptydirs[dir]++
            else
                withfiles[dir]++
        }
        else if (fc == "")
            withdirs[dir]++

        else if (fc != "")
            withboth[dir]++

        else
            nonemptydirs[dir]++

        if (fz != "")
            withempty[dir]++

        if (fnz != "")
        {
            withdata[dir]++
            datafiles += fnz

            if (fz != "")
                withmix[dir]++
        }

        if (fc != "")
        {
            totalfiles += fc
            nonemptydirs[dir]++

            if (fz != "")
                emptyfiles += fz
        }

        if (favg != "")
        {
            datasize += favg
        }
    }

    totaldirs = countarr(arr)
    divisor = countarr(withdata)

    print ""

    # Total directories processed:
    print "Total dirs:", totaldirs

    # Empty directories:
    print "Empty dirs:", countarr(emptydirs) + 0

    if (totaldirs > 1)
    {
        # Non-empty directories:
        print "Non-empty dirs:", countarr(nonemptydirs) + 0

        # Directories containing only subdirectories, no files:
        printf "    %-s %d\n", "containing only subdirs:",
               countarr(withdirs) + 0

        # Directories containing >= 1 file(s), no subdirectories:
        printf "    %-s %d\n", "containing only files:",
               countarr(withfiles) + 0

        # Directories containing both >= 1 file(s) and >= 1 directory(ies)
        printf "    %-s %d\n", "containing files and subdirs:",
               countarr(withboth) + 0

        # Directories containing zero-byte files:
        printf "    %-s %d\n", "containing empty files:",
                countarr(withempty) + 0

        # Directories containing non-empty files:
        printf "    %-s %d\n", "containing non-empty files:", divisor

        # Directories containing empty and non-empty files:
        printf "    %-s %d\n", "containing empty and non-empty files:",
               countarr(withmix)
    }

    # Total files:
    print "Total files:", totalfiles + 0

    if (totalfiles)
    {
        # Zero-byte files:
        print "Empty files:", emptyfiles + 0

        # Files >= 1 bytes:
        print "Non-empty files:", datafiles + 0

        if (divisor)
        {
            # Average number of non-empty files per non-empty dir:
            printf "    %-s %d\n", "avg. count per dir:",
                   datafiles / divisor

            # Average size of non-empty files size per non-empty dir:
            printf "    %-s %d\n", "avg. size per dir:",
                   datasize / divisor
        }
    }
}
