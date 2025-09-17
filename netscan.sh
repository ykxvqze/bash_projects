#!/usr/bin/env bash

<< 'EOF'
Scan LAN to discover IP and MAC addresses of connected devices on the network.

USAGE:  sudo ./netscan.sh [ -i <interface> ]

OPTIONS:
       [ -h ]              Print usage
       [ -i <interface> ]  An optional switch to specify a network interface.
                           If unspecified, the default interface is used.

OUTPUT:
        A listing of IP and MAC addresses of all network devices in
        tabular format via stdout.

DESCRIPTION:

The script checks for nmap and arp-scan tools. It then identifies the
default network interface and its IPv4 and MAC address. The script uses
the default interface unless one is provided via the -i switch. The IP
address range to scan is derived from the netmask. nmap runs over this
range via ping-scan mode (i.e., no port scanning or OS detection).
Additionally, arp-scan is executed following nmap. Both scans are repeated,
resulting in 4 scans in total in order not to miss any device. The results
are then merged together. Finally, an entry for localhost IP and MAC address
is appended and the result is displayed in tabular format.

ADDITIONAL NOTES:

If you control the gateway router on your LAN, you can check its ARP or
DHCP table by accessing the router via browser. The entries for the DHCP
leases given to various devices reveal their IP and MAC addresses.
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
IP Address Range :   192.168.1.3/24
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
__get_iface_default          () { :; }
__get_iface_list             () { :; }
__get_MAC                    () { :; }
__get_ip_cidr                () { :; }
__run_nmap                   () { :; }
__run_arpscan                () { :; }
__parse_options              () { :; }
__check_euid                 () { :; }
__check_nmap_installed       () { :; }
__check_arpscan_installed    () { :; }
__create_temporary_files     () { :; }
__check_concurrent_execution () { :; }
__set_traps                  () { :; }
__set_interface              () { :; }
__run_nmap_arpscan           () { :; }
__merge_results              () { :; }
__set_colors                 () { :; }
__print_result               () { :; }
__main                       () { :; }

__print_usage() {
    echo -e "netscan: detect devices connected to your network.

    Usage: sudo ./${0##*/}

    [ -i <interface> ]  Specify network interface (otherwise default is assumed)
    [ -h ]              Print usage and exit \n"
}

__check_euid() {
    if [[ "$EUID" != 0 ]]; then
        echo "Use sudo to run the script: sudo ./${0##*/}"
        echo "Exiting..."
        exit 1
    fi
}

__check_nmap_installed() {
    if [[ -z "$(which nmap)" ]]; then
        echo "Install nmap first, e.g.: sudo apt-get install nmap"
    fi
}

__check_arpscan_installed() {
    if [[ -z "$(which arp-scan)" ]]; then
        echo "Install arp-scan, e.g.: sudo apt-get install arp-scan"
    fi
}

__create_temporary_files() {
    file_nmap="$(mktemp /tmp/file_nmap.$$.XXXXXX)"
    file_arp="$(mktemp /tmp/file_arp.$$.XXXXXX)"
    file_results="$(mktemp /tmp/file_results.$$.XXXXXX)"
    file_pid="/tmp/${0##*/}.pid"
}

__check_concurrent_execution() {
    if [[ -f "${file_pid}" ]]; then
        echo "A concurrent execution is already running: PID $(cat ${file_pid})"
        echo "If not, delete ${file_pid}"
        exit 1
    fi
    echo $$ > "${file_pid}"
}

__set_traps() {
    trap 'rm ${file_pid} ${file_nmap} ${file_arp}' SIGINT SIGTERM EXIT
    trap 'echo error on line: $LINENO' ERR
}

__parse_options() {
    while getopts 'i:h' option; do
        case "$option" in
            h) __print_usage; exit 0;;
            i) iface="$OPTARG";;
            *) __print_usage; exit 1;;
        esac
    done
}

__get_iface_default() {
    iface_default="$(ip route show default | head -1 | cut -d ' ' -f 5)"
}

__get_iface_list() {
    iface_list="$(ip link | grep -E '^[0-9]:' | cut -d ':' -f 2 | grep -Ev 'lo$')"
}

__set_interface() {
    __get_iface_default
    __get_iface_list

    if [[ -z "${iface}" ]] || [[ -z "$(grep "${iface}" <<< "${iface_list}")" ]]; then
        echo "Supplied network interface does not exist. Reverting to default ${iface_default}"
        iface="${iface_default}"
    fi
}

__get_MAC() {
    MAC="$(ip link show "${iface}" | grep 'ether' | awk '{print $2}')"
}

__get_ip_cidr() {
    ip_cidr="$(ip -o -4 address show "${iface}" | tr -s ' ' | cut -d ' ' -f 4)"
}

__run_nmap() {
    nmap -e "${iface}" -sn "${ip_cidr}"
}

__run_arpscan() {
    arp-scan -I "${iface}" "${ip_cidr}"
}

__run_nmap_arpscan() {
    n_repeat=2
    for i in $(seq 1 "${n_repeat}"); do
        echo "[*] Running nmap scan: round ${i} of ${n_repeat}..."
        output="$(__run_nmap | grep -E -A 2 "([0-9]{1,3}\.){3}[0-9]{1,3}$")" 
        ip_addresses="$(echo "$output" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}$")"
        mac_addresses="$(echo "$output" | grep "MAC" | awk '{print $3}' | tr '[:upper:]' '[:lower:]')"
        paste <(echo "$ip_addresses") <(echo "$mac_addresses") | awk 'NF==2' >> "${file_nmap}"

        echo "[*] Running arp scan: round ${i} of ${n_repeat}..."
        __run_arpscan 2> /dev/null | grep -E '^[0-9]{1,3}\.' | cut -f 1,2 >> "${file_arp}"
    done
}

__merge_results() {
    sort -u "${file_nmap}" "${file_arp}" > "${file_results}"

    # add localhost entry
    echo -e "${ip_cidr%/*}\t${MAC} (*)" >> "${file_results}"
}

__set_colors() {
    DEFAULT="$(tput sgr0)"
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
}

__print_result() {
    __set_colors
    echo -e ''
    echo -e "Network Interface:\t ${iface}"
    echo -e "IP Address Range :\t ${ip_cidr}"
    echo -e "${RED}-----------------------------------------${DEFAULT}"
    echo -e 'Devices on LAN:'
    echo -e "${GREEN}IP_address\tMAC_address ${DEFAULT}"
    cat "${file_results}" | sort -u -k 1
}

__main() {
    __parse_options "$@"
    __check_euid
    __check_nmap_installed
    __check_arpscan_installed
    __create_temporary_files
    __check_concurrent_execution
    __set_traps
    __set_interface
    __get_MAC
    __get_ip_cidr
    __run_nmap_arpscan
    __merge_results
    __print_result
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
