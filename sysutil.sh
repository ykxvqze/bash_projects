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

usage(){
    echo -e "sysutil.sh: utility functions for daily sysops.
    Usage:

    . ./sysutil.sh           # Source the script, then...
    battery_status           # Show battery percentage charge remaining
    userinfo                 # List users currently logged in
    ports_open               # List TCP ports open on localhost
    sysinfo                  # List user/superuser, OS info, RAM, local/global IP address
    config_files             # Check for existence of important configuration files
    log_rotate <file>        # Split file if > 100mB into smaller ones (<= 100mB), gzip
                             # them and store as <file>.<i>.gz
    mysql_backup [ -r ]      # Backup all mysql databases into ~/backup/mysql/ and optionally
                             # use switch -r for sending the backup to remote server over rsync;
                             # (backups older than 1 week are automatically deleted afterwards).\n"
}

log_message(){
    echo `date +'%Y-%m-%d %T'` "$@"
}

battery_status(){
    percent_charge=`acpi                  |
                    cut -d ' ' -f 4       |
                    grep -oE '[0-9]{1,2}'`
    log_message "Battery currently at ${percent_charge}%"
}

userinfo(){
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

ports_open(){
    netstat -atn              |  # tcp ports open on host
    grep '^tcp'               |
    tr -s ' '                 |
    cut -d ' ' -f 4           |
    grep -oE '[^:][0-9]{1,}$' |
    sort -un                  |
    xargs
}

sysinfo(){
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

config_files(){
    files=('/etc/group' '/etc/hosts' '/etc/login.defs' '/etc/crontab' '/etc/sysctl.conf'
           '/etc/ssh/ssh_config' '/etc/ssh/sshd_config' '/etc/resolv.conf' '/etc/syslog.conf'
           '/etc/samba/smb.conf' '/etc/ldap/ldap.conf' '/etc/fstab' '/etc/fuse.conf'
           '/etc/host.conf' '/etc/ld.so.conf' '/etc/logrotate.conf' '/etc/netconfig')
    echo ''
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

log_rotate(){
    logfile="$1"
    filesize_max='100M'
    rm "$logfile".* 2> /dev/null
    split -b "$filesize_max" "$logfile" "${logfile}."  # ordered alphabetically: ${logfile}.a...

    i=1
    for file_ in `ls "$logfile".*`; do
        cat "$file_" | gzip > "${logfile}".$i.gz
        rm "$file_"
        let i++
    done
}

mysql_backup(){
    # USAGE:
    #   mysql_backup
    #   mysql_backup -r  # i.e. also rsync the backup to remote server

    path_to_backup="$HOME/backup/mysql/"
    n_to_keep='7'  # number of mysql backups (days) to keep

    # rsync to another server
    remote_host='remote.server'
    remote_user='user'
    remote_dir='/mysql_backup/'
    rsync_port='22'  # use default SSH port 22 (or another)

    if [ ! -d "$path_to_backup" ]; then
        mkdir -p "$path_to_backup"
    fi

    # check if able to connect to mysql server
    sudo mysql -e '' && echo 'Connection to mysql successful.' || echo 'Connection to mysql failed.'
    sudo mysql -V 2> /dev/null

    # ignore system dbs
    dbs=`sudo mysql -Bse 'show databases'`
    dbs_ignore='information_schema mysql performance_schema'

    for i in $dbs_ignore; do
        dbs=`echo $dbs | sed "s/\b${i}\b//g"`
    done
    dbs=($dbs)

    # do backups
    for db in "${dbs[@]}"; do
        echo "Dumping $db ..."
        sudo mysqldump --opt --skip-add-locks $db | bzip2 > ${path_to_backup}${db}_`date +'%Y-%m-%d'`.sql.bz2
    done

    # Delete old backups
    echo "------------------------------------"
    echo "Deleting old backups ..."
    find $path_to_backup -type f -name '*.sql.bz2' -mtime +$n_to_keep                   # show in stdout
    find $path_to_backup -type f -name '*.sql.bz2' -mtime +$n_to_keep -exec rm -f {} +  # delete backups older than 'n_to_keep' days
    echo "------------------------------------"
    echo "Backup complete: `date`"

    # rsync backups with another server
    if [ "$1" == '-r' ]; then
        echo "------------------------------------"
        echo "Sending backups to remote server..."
        sudo rsync --del -vaze "ssh -p $rsync_port" $path_to_backup $remote_user@$remote_host:$remote_dir
    fi
}
