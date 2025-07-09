#!/usr/bin/env bash

<< 'EOF'
Scan LAN to discover IP and MAC addresses of connected devices on the network.

USAGE:  sudo ./netscan.sh [ -i <interface> ]

OPTIONS:
       [ -h ]              Print usage
       [ -i <interface> ]  An optional switch to specify a network interface.
                           If unspecified, the default interface is used.
                           Note that the IP range to scan is automatically
                           deduced from the netmask.

OUTPUT:
        A listing of IP and MAC addresses of all network devices in
        tabular format via stdout.

DESCRIPTION:

The script checks for nmap and arp-scan tools and prompts to install them
if missing. It then extracts the name of the default network interface and
its local IPv4 and MAC address. The script uses the default interface
unless one is provided via the -i switch. The IP address range to scan
is derived from the netmask. Then, nmap is executed over this range via
ping-scan mode (i.e. no port scanning or OS detection). Additionally,
arp-scan is executed following nmap. Both scans are repeated resulting in
4 scans in total. The reason for repeating the scans is to avoid missing
any devices. The aggregate results of the scans are sorted and made unique.
An arp-scan returns both IP and MAC addresses, whereas nmap detects only
IP addresses. IP addresses that may have been detected by nmap but not by
arp-scan are appended to the final result. In such cases, the corresponding
MAC addresses are fetched from the local ARP cache/table which would have
logged relevant entries as the system pinged other devices during the nmap
and arp-scan procedures. Finally, an entry for localhost IP and MAC address
is appended and the result is displayed in tabular format.
Note: all devices on the LAN, including routers, will show in the table,
except those whose iptables are configured not to respond to ICMPs.

ADDITIONAL NOTES:

If you control the gateway router on your LAN, you can check its ARP or
DHCP table by accessing the router menu via browser. The entries for the
DHCP leases given to various devices reveal their IP and MAC addresses.
The ARP table will show all devices the router has communicated with.
Listings will be similar to the result you get from running this script,
except that you do not need to control or check the gateway itself - you
only need to be connected to the network as any other device.

DEMONSTRATION:

sudo ./netscan.sh

Output:

[*] Running nmap scan: round 1 of 2...
[*] Running arp scan: round 1 of 2...
[*] Running nmap scan: round 2 of 2...
[*] Running arp scan: round 2 of 2...

Network Interface:   wlp3s0
IP Address Range:    192.168.1.3/24
------------------------------------
Devices on LAN:
IP_address      MAC_address
192.168.1.1     XX:XX:XX:XX:XX:XX
192.168.1.3     XX:XX:XX:XX:XX:XX (*)
192.168.1.4     XX:XX:XX:XX:XX:XX
192.168.1.6     XX:XX:XX:XX:XX:XX
192.168.1.7     XX:XX:XX:XX:XX:XX
192.168.1.9     XX:XX:XX:XX:XX:XX
EOF

__print_usage                () { :; }
__get_default_iface          () { :; }
__get_all_ifaces             () { :; }
__get_mac                    () { :; }
__get_ips                    () { :; }
__run_nmap                   () { :; }
__run_arpscan                () { :; }
__parse_options              () { :; }
__check_euid                 () { :; }
__check_debian               () { :; }
__check_nmap_installed       () { :; }
__check_arpscan_installed    () { :; }
__create_temporary_files     () { :; }
__check_concurrent_execution () { :; }
__set_traps                  () { :; }
__check_interface            () { :; }
__get_interface_mac_ip       () { :; }
__run_nmap_arpscan           () { :; }
__get_nmap_exclusive_ips     () { :; }
__append_additional_ips      () { :; }
__set_colors                 () { :; }
__print_result               () { :; }
__main                       () { :; }

__print_usage() {
    echo -e "netscan: detect devices connected to your network.

    Usage: sudo ./${0##*/}

    [ -i <interface> ]  Specify network interface (otherwise default assumed)
    [ -h ]              Print usage and exit\n"
}

__get_default_iface(){
    ip route show default | head -1 | cut -d ' ' -f 5
}

__get_all_ifaces(){
    ip link           |
    grep -E '^[0-9]:' |
    cut -d ':' -f 2   |
    grep -Ev 'lo$'
}

__get_mac(){
    local interface="${1}"
    ip link show "${interface}" |
    grep 'ether'                |
    awk '{print $2}'
}

__get_ips(){
    local interface="${1}"
    ip -o -4 address show "${interface}" |
    tr -s ' '                            |
    cut -d ' ' -f 4
}

__run_nmap(){
    local interface="${1}"
    local ip_cidr="${2}"
    nmap -e "${interface}" -sn "${ip_cidr}" |
    grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}$"
}

__run_arpscan(){
    local interface="${1}"
    local ip_cidr="${2}"
    arp-scan -I "${interface}" "${ip_cidr}" 2> /dev/null |
    grep -E '^[0-9]{1,3}\.'                              |
    cut -f 1,2
}

__parse_options() {
    while getopts 'i:h' option; do
        case $option in
            h) __print_usage;  exit 0 ;;
            i) iface="$OPTARG"      ;;
            *) __print_usage;  exit 1 ;;
        esac
    done
}

__check_euid() {
    if [ "$EUID" != 0 ]; then
        echo "Use sudo to run the script: sudo ./${0##*/}"
        echo "Exiting..."
        exit 1
    fi
}

__check_debian() {
    dpkg --version &> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "Not a Debian-based distribution."
        echo "Exiting..."
        exit 1
    fi
}

__check_nmap_installed() {
    if [ -z "$(which nmap)" ]; then
        echo "nmap not found. Script will exit unless you allow installing nmap."
        read -p "Install nmap? (y/n): " -n 1 reply
        if [ "${reply,,}" == 'y' ]; then
            apt-get install nmap
        elif [ "${reply,,}" == 'n' ]; then
            echo 'Exiting...'
            exit 0
        else
            echo 'Invalid response. Exiting...'
            exit 1
        fi
    fi
}

__check_arpscan_installed() {
    if [ -z "$(which arp-scan)" ]; then
        echo "arp-scan not found. Script will exit unless you allow installing arp-scan."
        read -p "Install arp-scan? (y/n): " -n 1 reply
        if [ "${reply,,}" == 'y' ]; then
            apt-get install arp-scan
        elif [ "${reply,,}" == 'n' ]; then
            echo 'Exiting...'
            exit 0
        else
            echo 'Invalid response. Exiting...'
            exit 1
        fi
    fi
}

__create_temporary_files() {
    file_nmap=$(mktemp /tmp/file_nmap.XXXXXX)
    file_arp=$(mktemp /tmp/file_arp.XXXXXX)
    PID_FILE="/tmp/${0##*/}.pid"
}

__check_concurrent_execution() {
    if [ -f "${PID_FILE}" ]; then
        echo "A concurrent execution is already running: PID $(cat ${PID_FILE})"
        echo "If not, delete ${PID_FILE}"
        exit 1
    fi
    echo $$ > "${PID_FILE}"
}

__set_traps() {
    trap 'rm ${PID_FILE} ${file_nmap} ${file_arp}' SIGINT SIGTERM EXIT
    trap 'echo error on line: $LINENO' ERR
}

__check_interface() {
    iface_default=$(__get_default_iface)
    ifaces_list=$(__get_all_ifaces)
    if [ -z "${iface}" -o -z "$(grep "${iface}" <<< "${ifaces_list}")" ]; then
        echo "Supplied network interface does not exist. Reverting to default ${iface_default}"
        iface="${iface_default}"
    fi
}

__get_interface_mac_ip() {
    MAC=$(__get_mac "${iface}")
    IPs=$(__get_ips "${iface}")
}

__run_nmap_arpscan() {
    n_repeat=2
    for i in $(seq 1 "${n_repeat}"); do
        echo "[*] Running nmap scan: round ${i} of ${n_repeat}..."
        __run_nmap "${iface}" "${IPs}" >> "${file_nmap}"

        echo "[*] Running arp scan: round ${i} of ${n_repeat}..."
        __run_arpscan "${iface}" "${IPs}" >> "${file_arp}"
    done
}

__get_nmap_exclusive_ips() {
    # IP addresses detected by nmap but not by arp-scan
    IP_plus=$(comm -13 <(cut -f 1 "${file_arp}" | sort -u) <(cat "${file_nmap}" | sort -u))
}

__append_additional_ips() {
    # construct results table
    for i in ${IP_plus}; do
        table_plus=$(arp | grep -E "$i\s" | tr -s ' ' | cut -d ' ' -f 1,3 | tr ' ' '\t')
        if [ -n "${table_plus}" ]; then
            echo -e "${table_plus}"
        else
            echo -e "$i\tMAC_not_available"
        fi
    done  >> "${file_arp}"

    # add localhost entry to table and add a (*) sign
    echo -e "${IPs%/*}\t${MAC} (*)" >> "${file_arp}"
}

__set_colors() {
    DEFAULT='\e[0m'
    RED='\e[31m'
    GREEN='\e[32m'
}

__print_result() {
    __set_colors
    echo ''
    echo -e "Network Interface:\t $iface"
    echo -e "IP Address Range:\t $IPs"
    echo -e "${RED}-----------------------------------------${DEFAULT}"
    echo 'Devices on LAN:'
    echo -e "${GREEN}IP_address\tMAC_address ${DEFAULT}"
    cat "${file_arp}" | sort -u -k 1
}

__main() {
    __parse_options "$@"
    __check_euid
    __check_debian
    __check_nmap_installed
    __check_arpscan_installed
    __create_temporary_files
    __check_concurrent_execution
    __set_traps
    __check_interface
    __get_interface_mac_ip
    __run_nmap_arpscan
    __get_nmap_exclusive_ips
    __append_additional_ips
    __print_result
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    __main "${@}"
fi
