#!/usr/bin/awk -f

# update-rsyslog -- finds new logs and adds them to newsyslog.conf with default
#                   rotation parameters

BEGIN \
{
    config      = "/etc/newsyslog.conf"
    logdir      = "/var/log/hosts"
    exclude     = ("*.gz,*.[0-9],*.out,*.old,*.log,*.st")
    pid         = "/var/run/rsyslogd.pid"
    fmt_line    = "%-40s%-20s%-5s%-6s%-9s%-6s%-6s%-37s\n"

    split(exclude,arr,",")

    for ( i in arr ) {
        args = (args sep "-name \"" arr[i] "\"")
        sep = " -o "
    }

    find = ( "find " logdir " -type f \\! \\( " args " \\)" )

    while ((getline < config) > 0)
        ( $1 ~ /^\// ) && entry[$1]

    while ((find | getline) > 0) {
        fname[$1]
    } ; close(find)

    for ( i in fname ) {
        if (( i in entry ) == 0)
            printf fmt_line, i, "", "640", "7", "250", "*", "ZB", pid >> config
    }
}
