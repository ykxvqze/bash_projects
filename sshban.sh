#!/usr/bin/env bash
: '
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

'

ssh_blacklist='ssh_blacklist.txt'
ssh_badlogin='/tmp/ssh_badlogin.txt'
logfile='/tmp/logfile.txt'
recipient='sysadmin'

print_usage() {
    echo -e "sshban.sh:
    Usage:
    ./${0##*/}             Check /var/log/auth.log, send alert and ban repeated failed SSH attempts
    ./${0##*/} [ -h ]      Print usage and exit
    ./${0##*/} [ -l ]      List the log\n"
}

ban_ip() {
    IP="${1}"
    sudo iptables -A INPUT -s "${IP}" -j DROP
    sudo iptables-save
}

add_to_blacklist() {
    IP="${1}"
    echo "${IP}" >> "${ssh_blacklist}"
}

notify_mail() {
    IP="${1}"
    n_attempts="${2}"
    echo "[!] Notification of failed SSH login attempts from ${IP} (${n_attempts} failed attempts). IP address has been blocked." |
    mail -s 'SSH failed logins' "${recipient}"
}

is_ip_blacklisted() {
    IP="${1}"
    grep "${IP}" "${ssh_blacklist}" &> /dev/null && return 0 || return 1
}

get_log() {
    sudo cat /var/log/auth.log |
    grep -i 'sshd.*fail'       |
    grep -ho 'rhost=.*\s'      |
    grep -Eo '[^=]+$' > "${ssh_badlogin}"

    sort "${ssh_badlogin}" |
    uniq -c                |
    sort -nr -k 1          |
    sed -E 's/\s //g'
}

main() {
    while getopts 'hl' option; do
        case $option in
            h) print_usage;  exit 0 ;;
            l) get_log              ;;
            *) echo -e 'Incorrect usage!\n';
               print_usage;  exit 1 ;;
        esac
    done

    [ -f "${ssh_badlogin}" ] && rm -rf "${ssh_badlogin}"
    [ ! -f "${ssh_blacklist}" ] && touch "${ssh_blacklist}"

    get_log > "${logfile}"
    n_entries=$(cat ${logfile} | wc -l)
    n_attempts=($(cut -d ' ' -f 1 "${logfile}"))
    ip_list=($(cut -d ' ' -f 2 "${logfile}"))

    for i in $(seq 1 "$n_entries"); do
        index=$((i-1))
        IP="${ip_list[$index]}"
        n="${n_attempts[$index]}"
        if [ "$n" -gt 4 ]; then
            if [ ! $(is_ip_blacklisted "${IP}") ]; then
                add_to_blacklist "${IP}"
                ban_ip "${IP}"
                notify_mail "${IP}" "${n}"
            fi
        fi
    done
}

main "$@"
