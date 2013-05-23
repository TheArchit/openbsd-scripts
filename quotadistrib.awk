#!/usr/bin/awk -f

BEGIN {
    FS = "[:,]"

    while ((getline < "/etc/group") > 0) {
        sub(/[: ]+$/, "")
        for (i=1; i<=NF; i++) {
            if (i > 3)
                arr[$1] = (arr[$1] " " $i)
        }
    }

    for (i in arr)
        print i ":", arr[i]
}
