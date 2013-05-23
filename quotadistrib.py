#!/usr/local/bin/python -S

from sys import argv
import subprocess

def main():
    groups = {}
    users = []
    for line in open('/etc/group'):
        # return a set of users common across groups specified on
        # the command line
        if line[-2] != ':' and line.split(':')[0] in argv[1:]:
            users = set.union(set([ x.split(':')[-1] for x in
                line.splitlines()[0].split(',')[0:]]), users)

    users.discard('thearchit')
    print users

if __name__ == '__main__':
    main()
