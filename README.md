Utilities to do various things on OpenBSD systems, possibly Linux as well.

diravg.awk:
--------------
Utility that displays file distribution statistics which may be useful for 
tuning filesystem parameters with 'tunefs'.

fsdump:
------
Performs a dump of each filesystem listed by "dump w" in an odd/even rotation
scheme: 0,3,4,7,8,1,2,5,6,9,0

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
Updates the OpenBSD ports tree (/usr/ports), userland (/usr/src) and kernel
sources (/usr/src/sys) from CVS. The folloving variables should be adjusted to
match the OpenBSD branch and preferred anonymous CVS server.

    cvs_repos="anoncvs@anoncvs.spacehopper.org:/cvs"
    branch="stable" # "current" or "stable"

'srcupdate' logs its progress via syslog to the daemon facility. When updates
are found, it creates a symlink to the updated source under /var/srcupdate

For the time being it assumes OpenBSD_5.3 but I'll keep making adjustments to
add more flexibility.

libdeps.awk: (indev)
-----------
Tool to copy the specified binary and all its library dependencies to a chroot
environment

quotadistrib.py: (indev)
---------------
Take a prototype user and apply its disk quotas to all the users in the 
specified groups

quotadistrib.awk: (indev)
----------------
Same as quotadistrib.py but written in AWK
