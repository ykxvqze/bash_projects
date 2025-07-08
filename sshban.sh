#!/usr/bin/env bash

<< 'EOF'
Process server authentication logs, send alert and ban repeated failed SSH attempts.

USAGE: ./sshban.sh [ -h ]

OPTIONS:
      [ -h ]  Print usage
      [ -l ]  Print logfile (table) containing blacklisted IP addresses
              along with their count (number of failed SSH attempts).

OUTPUT:
      file:   ./ssh_blacklist.txt (containing blacklisted IP addresses)

DESCRIPTION:

The log file /var/log/auth.log is processed, and failed SSH logins are
logged into a temporary file which is then processed to create a table
of unique IP addresses that have attempted to log in, along with
the number of attempts in each case. Based on this table, if an IP
address appears more than 4 times _and_ is not already logged in
./ssh_blacklist.txt, the following actions are taken:

  1. The IP address is added to ./ssh_blacklist.txt.
  2. The IP address gets banned by creating an iptables entry blocking it as source.
  3. A mail notification of the event is sent out to a preset email address

Note: execute the script as a cron job (e.g. every 2 minutes).
*/2 * * * * /path/to/sshban.sh
EOF

ssh_blacklist='ssh_blacklist.txt'
ssh_badlogin='/tmp/ssh_badlogin.txt'
logfile='/tmp/logfile.txt'
recipient='sysadmin'

__check_euid        () { :; }
__print_usage       () { :; }
__parse_options     () { :; }
__ban_ip            () { :; }
__add_to_blacklist  () { :; }
__notify_mail       () { :; }
__is_ip_blacklisted () { :; }
__get_log           () { :; }
__process_log       () { :; }
__main              () { :; }

__check_euid() {
    if [ "$EUID" != 0 ]; then
        echo "Use sudo to run the script: sudo ./${0##*/}"
        echo "Exiting..."
        exit 1
    fi
}

__print_usage() {
    echo -e "
    Usage:

    ./${0##*/} [ -h ]           Print usage and exit
    sudo ./${0##*/}             Check /var/log/auth.log, send alert and ban repeated failed SSH attempts
    sudo ./${0##*/} [ -l ]      List the log\n"
}

__parse_options() {
    while getopts 'hl' option; do
        case $option in
            h) __print_usage;  exit 0 ;;
            l) __check_euid; __get_log;;
            *) echo -e 'Incorrect usage!\n';
               __print_usage;  exit 1 ;;
        esac
    done
}

__ban_ip() {
    IP="${1}"
    iptables -A INPUT -s "${IP}" -j DROP
    iptables-save
}

__add_to_blacklist() {
    IP="${1}"
    echo "${IP}" >> "${ssh_blacklist}"
}

__notify_mail() {
    IP="${1}"
    n_attempts="${2}"
    echo "[!] Notification of failed SSH login attempts from ${IP} (${n_attempts} failed attempts). IP address has been blocked." |
    mail -s 'SSH failed logins' "${recipient}"
}

__is_ip_blacklisted() {
    IP="${1}"
    grep "${IP}" "${ssh_blacklist}" &> /dev/null && return 0 || return 1
}

__get_log() {
    cat /var/log/auth.log      |
    grep -i 'sshd.*fail'       |
    grep -ho 'rhost=.*\s'      |
    grep -Eo '[^=]+$' > "${ssh_badlogin}"

    sort "${ssh_badlogin}" |
    uniq -c                |
    sort -nr -k 1          |
    sed -E 's/\s //g' > "${logfile}"
}

__process_log() {
    [ -f "${ssh_badlogin}" ] && rm -rf "${ssh_badlogin}"
    [ ! -f "${ssh_blacklist}" ] && touch "${ssh_blacklist}"

    n_entries=$(cat ${logfile} | wc -l)
    n_attempts=($(cut -d ' ' -f 1 "${logfile}"))
    ip_list=($(cut -d ' ' -f 2 "${logfile}"))

    for i in $(seq 1 "$n_entries"); do
        index=$((i-1))
        IP="${ip_list[$index]}"
        n="${n_attempts[$index]}"
        if [ "$n" -gt 4 ]; then
            if [ ! $(__is_ip_blacklisted "${IP}") ]; then
                __add_to_blacklist "${IP}"
                __ban_ip "${IP}"
                __notify_mail "${IP}" "${n}"
            fi
        fi
    done
}

__main() {
    __parse_options "$@"
    __check_euid
    __get_log
    __process_log
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    __main "$@"
fi
