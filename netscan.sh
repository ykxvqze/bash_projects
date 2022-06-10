#!/usr/bin/env bash
: '
Scan LAN to discover IP and MAC addresses of all devices on the network.

USAGE:  ./netscan.sh [-I <interface>] [ -h ]

OPTIONS:
       [ -h ]              Print usage
       [ -I <interface> ]  An optional switch to specify a network interface.
                           If unspecified, the default interface is used.
                           Note that the IP range to scan is automatically
                           deduced from the netmask.

OUTPUT:
        A listing of IP and MAC addresses of all network devices in
        tabular format (via stdout)

DESCRIPTION:

The script checks for nmap and arp-scan tools and installs them if
missing (it assumes a Debian-based OS). It then extracts the name of the
default network interface and its local IPv4 and MAC address. The script
will use the default interface unless one is provided by the user via
the -I switch (and is a valid interface, otherwise the script will
revert to default interface). The IP address range to scan is derived
from the netmask. Then nmap is executed over the local IP network range
via ping-scan mode (i.e. no port scanning or OS detection).
Additionally, arp-scan is executed following nmap. Both scans are
repeated within a loop resulting in 4 scans in total; the reason for
repeating the scans is that a scan may miss some devices if only one
trial is attempted or if only 1 tool is used. The aggregated results of
the scans are sorted sorted and made unique. An arp-scan returns both IP
and MAC addresses, whereas nmap will be detecting only IP addresses. Any
IP addresses that may have been detected by nmap but not by arp-scan are
appended to the final result. In such cases, the corresponding MAC
addresses are fetched from the local ARP cache/table which would have
logged relevant entries as the system was pinging other devices during
the nmap and arp-scan procedures. Finally, an entry for localhost IP and
MAC address is appended (i.e. those of the system running the script)
and the result is displayed in tabular format. Note: all devices on the
LAN (including routers) will show in the table, except those whose
iptables are set not to respond to ICMPs or pings.

ADDITIONAL NOTES:

If you are on a home LAN and you control the gateway router, you can
check its ARP or DHCP table by accessing the router menu via browser.
The entries for the DHCP leases given to various devices will reveal
their IP and MAC addresses (note: some leases may be expired). The ARP
table will also show all devices the router has communicated with.
Listings will be similar to the result you get from running this script
(except that you do not need to control or check the gateway itself -
you only need to be connected to the network as any other device).

The library scapy in Python provides similar functionality as this
script, but it would be an overkill to use Python or to install a full
library if network scanning is your only aim. A Bash-native solution is
more efficient and suitable for system-level tasks.

Demonstration:

./netscan.sh

Output:

running nmap scan: round 1 of 2...
running arp scan: round 1 of 2...
running nmap scan: round 2 of 2...
running arp scan: round 2 of 2...

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

J.A., xrzfyvqk_k1jw@pm.me
'

print_usage() {
    echo -e "netscan: detect devices connected to your network.
    Usage: ./${0##*/}
    [ -I <interface> ]  Specify network interface (otherwise default assumed)
    [ -h ]              Print usage and exit\n"
}

get_default_iface(){
    sudo ip route show default |
    cut -d ' ' -f 5
}

get_all_ifaces(){
    sudo ip link      |
    grep -E '^[0-9]:' |
    cut -d ':' -f 2   |
    grep -Ev 'lo$'
}

get_mac(){
    sudo ip link show "$1" |
    grep 'ether'           |
    awk '{print $2}'
}

get_ips(){
    sudo ip -o -4 address show "$1" |
    tr -s ' '                       |
    cut -d ' ' -f 4
}

run_nmap(){
    sudo nmap -e "$1" -sn "$2" |
    grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}$"
}

run_arpscan(){
    sudo arp-scan -I "$1" "$2" 2> /dev/null |
    grep -E '^[0-9]{1,3}\.'                 |
    cut -f 1,2
}

main(){
    # parse input
    while getopts 'I:h' option; do
        case $option in
            h) print_usage;  exit 0 ;;
            I) iface="$OPTARG"      ;;
            *) print_usage;  exit 1 ;;
        esac
    done

    sudo echo > /dev/null
    if [ $? -ne 0 ]; then
        exit
    fi

    if [ -z "`sudo which nmap`" ]; then
        sudo apt-get install nmap
    fi

    if [ -z "`sudo which arp-scan`" ]; then
        sudo apt-get install arp-scan
    fi

    # temporary files
    file_nmap=`mktemp /tmp/file_nmap.XXXXXX`
    file_arp=`mktemp /tmp/file_arp.XXXXXX`

    # avoid concurrent executions
    if [ -e "${PID_FILE}" ]; then
        echo "A concurrent execution is already running: PID `cat ${PID_FILE}`"
        echo "If not, delete ${PID_FILE}"
        exit 1
    fi
    PID_FILE="/tmp/${0##*/}.pid"
    echo $$ > "${PID_FILE}"

    trap 'rm ${PID_FILE} ${file_nmap} ${file_arp}' SIGINT SIGTERM EXIT
    trap 'echo error on line: $LINENO' ERR

    iface_default=`get_default_iface`
    ifaces_list=`get_all_ifaces`
    if [ -z "$iface" -o -z "$(grep "$iface" <<< "$ifaces_list")" ]; then
        echo "Supplied network interface does not exist. Reverting to default $iface_default"
        iface="${iface_default}"
    fi

    MAC=`get_mac "$iface"`
    IPs=`get_ips "$iface"`

    n_repeat=2
    for i in `seq 1 "$n_repeat"`; do
        echo "running nmap scan: round ${i} of ${n_repeat}..."
        run_nmap "$iface" "$IPs" >> ${file_nmap}

        echo "running arp scan: round ${i} of ${n_repeat}..."
        run_arpscan "$iface" "$IPs" >> ${file_arp}
    done

    # IP addresses detected by nmap but not by arp-scan
    IP_plus=`comm -13 <(cut -f 1 "${file_arp}" | sort -u) <(cat "${file_nmap}" | sort -u)`

    # construct results table
    for i in ${IP_plus}; do
        table_plus=$(sudo arp          |
                     grep -E "$i\s"    |
                     tr -s ' '         |
                     cut -d ' ' -f 1,3 |
                     tr ' ' '\t')
        if [ -n "${table_plus}" ]; then
            echo -e "${table_plus}"
        else
            echo -e "$i\tMAC_not_available"
        fi
    done    >> "${file_arp}"

    # add localhost entry to table
    echo -e "${IPs%/*}\t$MAC (*)" >> "${file_arp}"

    # display
    DEFAULT='\e[0m'
    RED='\e[31m'
    GREEN='\e[32m'

    echo ''
    echo -e "Network Interface:\t $iface"
    echo -e "IP Address Range:\t $IPs"
    echo -e "${RED}----------------------------------------${DEFAULT}"
    echo 'Devices on LAN:'
    echo -e "${GREEN}IP_address\tMAC_address ${DEFAULT}"
    cat "${file_arp}" | sort -u -k 1
}

main "$@"
