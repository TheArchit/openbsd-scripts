#!/usr/bin/awk -f
#
#   diravg.awk  -- gathers file size statistics for a given tree
#
#   Usage: ./diravg.awk /path/to/tree
#
#   BUGS:
#           * won't handle non-printing characters in directory names
#           * this started as a futile recursion exercise and it's slow: we
#             call 'ls' on each directory. Performance will improve once
#             we make diravg() call 'ls -laR' once
#
#   TODO:
#           * function to convert bytes to specified units
#           * switch to system() in diravg() to evaluate 'ls' return status
#           * Think about reporting
#           * repeat heading every getenv[LINES]
#           * allow spaces in directory names passed via ARGV
#           * display stats for each directory passed via ARGV
#

function diravg(dir,    lno, dirc, fc, fmin, fzero, fnzero,
                fsum, fmax, name, i, regex)
{
    while (("ls -la " dir | getline) > 0)
    {
        lno++
        if (lno > 1)
        {
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
            {
                dirc++

                # deal with directories with spaces by enclosing them
                # within single-quotes, then recurse
                if (NF > 9)
                {
                    name = $0
                    for (i=1; i<=8; i++)
                    {
                        regex = ( "[ ]*" $i "[ ]*" )
                        sub(regex, "", name)
                    }
                    name = (  dir "/'" name "'" )
                }
                else
                    name = ( dir "/" $9 )

                diravg(name)
            }
            arr[dir] = ( dirc "," fc "," fzero "," fnzero "," fmin "," \
                fmax "," fsum )
        }
    }

    if (lno < 4)    # directory contains neither files nor subdirectories
        arr[dir] = ",,,,,,"

    close("ls -la " dir)
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
#                   val1: number of subdirectories
#                   val2: number of files
#                   val3: number of zero-byte files
#                   val4: number of non-empty files
#                   val5: size of smallest file in bytes
#                   val6: size of largest file in bytes
#                   val7: sum of all files in bytes
#
#   Array values can be split() using comma as the field delimiter.
#   Values can be null or a positive integer, for example if val2 (num files)
#   is null, there won't be any file statistics to display.
#

    fmt_dirc = "%7s"
    fmt_fc = "%7s"
    fmt_fz = "%7s"
    fmt_fnz = "%7s"
    fmt_fmin = "%10s"
    fmt_fmax = "%10s"
    fmt_fsum = "%10s"
    fmt_favg = "%10s"
    fmt_dir = " %s\n"

    printf fmt_dirc, "dirs:"
    printf fmt_fc, "files:"
    printf fmt_fz, "zero:"
    printf fmt_fnz, "nzero:"
    printf fmt_fmin, "fmin:"
    printf fmt_fmax, "fmax:"
    printf fmt_fsum, "fsum:"
    printf fmt_favg, "favg:"
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
        fsum = row[7]

        # zero-byte files have no weight in our avg file size
        # calculation
        if (fnz != "")
            favg = sprintf("%d", (fsum / fnz))
        else
            favg = fsum

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

        # Empty directories
        if (dirc == "" && fc == "")
        {
            emptydirs[dir]++
        }

        # Directories with files and/or directories
        if (dirc != "" || fc != "")
        {
            nonemptydirs[dir]++
        }

        # Directories containing only other subdirectories
        if (dirc != "" && fc == "")
        {
            withdirs[dir]++
        }

        # Directories containing just files
        if (dirc == "" && fc != "")
        {
            withfiles[dir]++
        }

        # Directories containing both files and directories
        if (dirc != "" && fc != "")
        {
            withboth[dir]++
        }

        # Directories containing empty files
        if (fz != "")
        {
            withempty[dir]++
        }

        # Directories containing non-empty files
        if (fnz != "")
            withdata[dir]++

        # Directories containing empty and non-empty files
        if (fz != "" && fnz != "")
            withmix[dir]++

        # Total number of files
        if (fc != "")
        {
            totalfiles += fc
        }

        # Empty files
        if (fc != "" && fz != "")
        {
            emptyfiles += fz
        }

        # Number of files with data
        if (fnz != "")
        {
            datafiles += fnz
        }

        # Sum of file averages
        if (favg != "")
        {
            datasize += favg
        }
    }

    totaldirs = countarr(arr)
    divisor = countarr(withdata)

    # Total directories processed:
    print "Total dirs:", totaldirs

    # Empty directories:
    print "Empty dirs:", countarr(emptydirs)

    if (totaldirs > 1)
    {
    # Non-empty directories:
    print "Non-empty dirs:", countarr(nonemptydirs)

    # Directories containing only subdirectories, no files:
    printf "    %-s %d\n", "containing only subdirs:", countarr(withdirs)

    # Directories containing >= 1 file(s), no subdirectories:
    printf "    %-s %d\n", "containing only files:", countarr(withfiles)

    # Directories containing both >= 1 file(s) and >= 1 directory(ies)
    printf "    %-s %d\n", "containing files and subdirs:", countarr(withboth)

    # Directories containing zero-byte files:
    printf "    %-s %d\n", "containing empty files:", countarr(withempty)

    # Directories containing non-empty files:
    printf "    %-s %d\n", "containing non-empty files:", divisor

    # Directories containing empty and non-empty files:
    printf "    %-s %d\n", "containing empty and non-empty files:", countarr(withmix)
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
            printf "    %-s %d\n", "avg. count per dir:", datafiles / divisor

            # Average size of non-empty files size per non-empty dir:
            printf "    %-s %d\n", "avg. size per dir:", datasize / divisor
        }
    }
}
