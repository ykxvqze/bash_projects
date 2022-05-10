#!/usr/bin/env bash
: '
Sysops utility functions.

USAGE: . ./sysutil.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

EXAMPLES:
         . ./sysutils.sh
         battery_status  # battery percentage charge remaining
         userlog         # list users currently logged in
	 ports_open      # list TCP ports open on localhost
'

usage() {
    echo -e "sysutil.sh: utility functions for daily sysops.
    Usage:
    . ./sysutil.sh           Source the script, then...
    userlog                  Call some utility function

    . ./sysutil.sh [ -h ]    Print usage and exit\n"
}

log_message() {
    echo `date +'%Y-%m-%d %T'` "$@"
}

battery_status() {
    percent_charge=`acpi                  |
                    cut -d ' ' -f 4       |
                    grep -oE '[0-9]{1,2}'`
    log_message "Battery currently at ${percent_charge}%"
}

userinfo() {
    self=`whoami`
    users_all=`who | cut -d ' ' -f 1 | sort -u`
    n_users=`who | cut -d ' ' -f 1 | sort -u | wc -l`
    n_sessions=`w -h | wc -l`

    echo 'Users currently logged in (self = *):'
    echo "$users_all" | sed "s/$self/& (*)/"
    echo "-------------------------------------"
    echo "Number of users: $n_users"
    echo "Number of sessions: $n_sessions"
}

ports_open() {
    netstat -atn              |  # tcp ports open on host
    grep '^tcp'               |
    tr -s ' '                 |
    cut -d ' ' -f 4           |
    grep -oE '[^:][0-9]{1,}$' |
    sort -un                  |
    xargs
}

sysinfo() {
    superuser=`grep ':x:0:' /etc/passwd | cut -d ':' -f 1`
    local_ip=`ip -o -4 address  |
	      tr -s ' '         |
	      grep -v 'lo inet' |
	      cut -d ' ' -f 4   |
	      sed 's/\/.*//'`
    global_ip=`wget -O - -q 'http://icanhazip.com'`

    echo "
    Username     : `whoami`
    User groups  : `groups $(whoami)`
    Superuser    : ${superuser}
    Hostname     : `hostname`
    OS           : `uname -mrs`
    Kernel       : `uname -r`
    Arch         : `uname -m`
    IP (local)   : ${local_ip}
    IP (global)  : ${global_ip}
    Ports open   : `ports_open`  
    RAM
     - MemTotal  : `free -m | grep '^Mem:'  | tr -s ' ' | cut -d ' ' -f 2` mB
     - MemFree   : `free -m | grep '^Mem:'  | tr -s ' ' | cut -d ' ' -f 4` mB
     - SwapTotal : `free -m | grep '^Swap:' | tr -s ' ' | cut -d ' ' -f 2` mB "
}

