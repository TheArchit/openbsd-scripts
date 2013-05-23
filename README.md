Utilities to do various things on OpenBSD systems, possibly Linux as well.

diravg.awk:
--------------
Utility that displays statistics which may be useful for tuning filesystem
parameters with 'tunefs'.

fsdump:
------
I wrote this to take automated differential backups from cron after an initial
dump of any filesystem has been taken. It runs 'dump w' and increases the dump
level according to a table. Finally takes a differential dump based on the
auto-selected level.

e.g.

    # set up the desired fstab dump frequency (field 6) for a given filesystem:
        /dev/sd1f   /var/postgresql ffs rw,nodev,nosuid,noexec,softdep 1 2

    # take an initial manual dump:
        $ dump 0auf | gzip -9 > outfile.gz

    # set up a cronjob that runs 'fsdump' every hour:
    55 */1 * * *        /root/sbin/fsdump

    # After 24 hours the filesystem will need dumping:
        $ dump w
    Dump these file systems:
      /dev/rsd1f    (/var/postgresql) Last dump: Level 5, Date Wed May 15 13:58

'fsdump' will now automatically pick it up.

srcupdate:
---------
Updates OpenBSD Ports (/usr/ports), userland sources (/usr/src) and kernel
sources /usr/src/sys from CVS. The folloving variables should be adusted to
match your OpenBSD branch and preferred CVS sources.

    cvs_repos="anoncvs@anoncvs.spacehopper.org:/cvs"
    branch="stable" # "current" or "stable"

It logs its progress via syslog to the daemon facility and when source updates
are found, it creates a symlink to the updated source under /var/srcupdate

For the time being it assumes you're on OpenBSD_5.3 but I'll keep making
improvements.

