#!/usr/bin/env bash
: '
Sysops utility functions.

USAGE: . ./sysutil.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

EXAMPLES:
         . ./sysutil.sh
         userinfo            # call a utility function
'

usage() {
    echo -e "sysutil.sh: utility functions for daily sysops.
    Usage:

    . ./sysutil.sh           # Source the script first to use the utility functions
    battery_status           # Show battery percentage charge remaining
    userinfo                 # List users currently logged in
    ports_open               # List TCP ports open on localhost
    sysinfo                  # List user/superuser, OS info, RAM, WAN/LAN/gateway IP addresses
    geodata                  # List country, city, and geo-coordinates based on IP address
    getmac <iface>           # Get MAC address of network interface <iface>
    config_files             # Check for existence of important configuration files
    log_rotate <file>        # Split file if > 100mB into smaller ones (<= 100mB), gzip
                             # them and store as <file>.<i>.gz
    mysql_backup [ -r ]      # Backup all mysql databases into ~/backup/mysql/ and optionally
                             # use switch -r for sending the backup to a remote server over rsync;
                             # (backups older than 1 week are automatically deleted afterwards).
    debugmode [ -s | -u ]    # Set an informative PS4 (debug) prompt and enable xtrace via -s;
                             # reset PS4 to default prompt (+) and disable xtrace mode via -u\n"
}

log_message() {
    echo $(date +'%Y-%m-%d %T') "$@"
}

battery_status() {
    percent_charge=$(acpi | cut -d ' ' -f 4)
    log_message "Battery currently at ${percent_charge}"
}

userinfo() {
    self=$(whoami)
    users_all=$(who | cut -d ' ' -f 1 | sort -u)
    n_users=$(who | cut -d ' ' -f 1 | sort -u | wc -l)
    n_sessions=$(w -h | wc -l)

    echo "Users currently logged in (self = *):"
    echo "$users_all" | sed "s/$self/& (*)/"
    echo "-------------------------------------"
    echo "Number of users: $n_users"
    echo "Number of sessions: $n_sessions"
}

# tcp ports open on host
ports_open() {
    netstat -atn              |
    grep '^tcp'               |
    tr -s ' '                 |
    cut -d ' ' -f 4           |
    grep -oE '[^:][0-9]{1,}$' |
    sort -un                  |
    xargs
}

sysinfo() {
    superuser=$(grep ':x:0:' /etc/passwd | cut -d ':' -f 1)

    ip_public=$(wget -q -O - 'ipinfo.io/ip')

    ip_private=$(ip -o -4 address    |
                 tr -s ' '           |
                 grep -v '127.0.0.1' |
                 cut -d ' ' -f 4     |
                 sed 's/\/.*//')

    ip_gateway=$(ip route            |
                 grep '^default via' |
                 head -1             |
                 cut -d ' ' -f 3)

    echo "
    Username       : $(whoami)
    User groups    : $(groups $(whoami) | cut -d ':' -f 2- | sed 's/^ //')
    Superuser      : ${superuser}
    Hostname       : $(hostname)
    OS             : $(uname -mrs)
    Kernel         : $(uname -r)
    Architecture   : $(uname -m)
    Logical cores  : $(cat /proc/cpuinfo | grep -c 'processor')
    Physical cores : $(grep "core id" /proc/cpuinfo | sort -u | wc -l)
    IP (Public)    : ${ip_public}
    IP (Private)   : ${ip_private}
    IP (Gateway)   : ${ip_gateway}
    Ports open     : $(ports_open)
    Memory
     - MemTotal    : $(free -m | grep '^Mem:'  | tr -s ' ' | cut -d ' ' -f 2) MB
     - MemFree     : $(free -m | grep '^Mem:'  | tr -s ' ' | cut -d ' ' -f 4) MB
     - SwapTotal   : $(free -m | grep '^Swap:' | tr -s ' ' | cut -d ' ' -f 2) MB "
}

geodata() {
    ip_public=$(wget -q -O - ipinfo.io/ip)

    ip_private=$(ip -o -4 address    |
                 tr -s ' '           |
                 grep -v '127.0.0.1' |
                 cut -d ' ' -f 4     |
                 sed 's/\/.*//')

    ip_gateway=$(ip route            |
                 grep '^default via' |
                 head -1             |
                 cut -d ' ' -f 3)

    country=$(wget -q -O - ipinfo.io/country)
    city=$(wget -q -O - ipinfo.io/city)
    loc=$(wget -q -O - ipinfo.io/loc)

    echo "
    IP (WAN)       : $ip_public
    IP (LAN)       : $ip_private
    IP (gateway)   : $ip_gateway
    Geo
     - Country     : $country
     - City        : $city
     - Coordinates : $loc "
}

getmac() {
    iface="${1}"
    ip link show $iface |
    grep 'ether'        |
    awk '{print $2}'
}

config_files() {
    files=('/etc/group' '/etc/hosts' '/etc/login.defs' '/etc/crontab' '/etc/sysctl.conf'
           '/etc/ssh/ssh_config' '/etc/ssh/sshd_config' '/etc/resolv.conf' '/etc/syslog.conf'
           '/etc/samba/smb.conf' '/etc/ldap/ldap.conf' '/etc/fstab' '/etc/fuse.conf'
           '/etc/host.conf' '/etc/ld.so.conf' '/etc/logrotate.conf' '/etc/netconfig')
    echo ''
    echo 'The following configuration files exist:'
    cnt=0
    for i in "${files[@]}"; do
        [ -f "$i" ] && echo "$i"
        ((cnt++))
    done

    if [ "$cnt" -eq 0 ]; then
        echo 'No configuration files found.'
    fi
}

log_rotate() {
    logfile="${1}"
    filesize_max='100M'
    rm "$logfile".* 2> /dev/null
    split -b "$filesize_max" "$logfile" "${logfile}."  # ordered alphabetically: ${logfile}.a...

    i=1
    for file_ in $(ls "$logfile".*); do
        cat "$file_" | gzip > "${logfile}".$i.gz
        rm "$file_"
        let i++
    done
}

mysql_backup() {
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
    dbs=$(sudo mysql -Bse 'show databases')
    dbs_ignore='information_schema mysql performance_schema'

    for i in $dbs_ignore; do
        dbs=$(echo $dbs | sed "s/\b${i}\b//g")
    done
    dbs=($dbs)

    # do backups
    for db in "${dbs[@]}"; do
        echo "Dumping $db ..."
        sudo mysqldump --opt --skip-add-locks $db | bzip2 > ${path_to_backup}${db}_$(date +'%Y-%m-%d').sql.bz2
    done

    # delete old backups
    echo "------------------------------------"
    echo "Deleting old backups ..."
    find $path_to_backup -type f -name '*.sql.bz2' -mtime +$n_to_keep                   # show in stdout
    find $path_to_backup -type f -name '*.sql.bz2' -mtime +$n_to_keep -exec rm -f {} +  # delete backups older than 'n_to_keep' days
    echo "------------------------------------"
    echo "Backup complete: $(date)"

    # rsync backups to another server
    if [ "$1" == '-r' ]; then
        echo "------------------------------------"
        echo "Sending backups to remote server..."
        sudo rsync --del -vaze "ssh -p $rsync_port" $path_to_backup $remote_user@$remote_host:$remote_dir
    fi
}

debugmode() {
    # PS1 is default (normal) prompt
    # PS2 is displayed when a command extends beyond 1 line as more keystrokes are awaited
    # PS3 is displayed when the 'select' command is used
    # PS4 is displayed when in debug mode (+)

    # USAGE:
    #   debugmode -s  # set a new PS4 prompt and enable xtrace mode
    #   debugmode -u  # unset back to default PS4 prompt (+) and disable xtrace mode
    case "$1" in
        -s) export PS4="+<${BASH_SOURCE[0]}>:<${FUNCNAME[0]}>:<${LINENO}> "
            set -o xtrace ;;
        -u) export PS4='+'
            set +o xtrace ;;
    esac
}
