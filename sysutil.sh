#!/usr/bin/env bash
: '
Sysops utility functions.

USAGE: . ./sysutil.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

EXAMPLES:
         . ./sysutil.sh
         battery_status      # battery percentage charge remaining
         userinfo            # call some utility function
'

usage() {
    echo -e "sysutil.sh: utility functions for daily sysops.
    Usage:

    . ./sysutil.sh           # source the script, then...
    battery_status           # battery percentage charge remaining
    userinfo                 # list users currently logged in
    ports_open               # list TCP ports open on localhost
    sysinfo                  # list user/superuser, OS info, RAM, local/global IP address
    config_files             # check for existence of important configuration files
    log_rotate               # split <file> if > 100mB into smaller ones (<= 100mB),
                             # gzip them and store these as <file>.<i>.gz\n"
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

config_files() {
    files=('/etc/group' '/etc/hosts' '/etc/crontab' '/etc/sysctl.conf' '/etc/ssh/ssh_config'
           '/etc/ssh/sshd_config' '/etc/resolv.conf' '/etc/syslog.conf' '/etc/samba/smb.conf'
           '/etc/ldap/ldap.conf' '/etc/fstab' '/etc/fuse.conf' '/etc/host.conf' '/etc/ld.so.conf'
           '/etc/logrotate.conf' '/etc/netconfig')

    echo 'The following configuration files exist:'
    cnt=0
    for i in ${files[*]}; do
        [ -f $i ] && echo $i
        ((cnt++))
    done

    if [ $cnt -eq 0 ]; then
        echo 'No configuration files found.'
    fi
}

log_rotate() {
    logfile="$1"
    filesize_max='10M'
    rm "$logfile".* 2> /dev/null
    split -b "$filesize_max" "$logfile" "${logfile}."  # ordered alphabetically: ${logfile}.a...

    i=1
    for file_ in `ls "$logfile".*`; do
        cat "$file_" | gzip > "${logfile}".$i.gz
        rm "$file_"
        let i++
    done
}
