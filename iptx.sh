#!/usr/bin/env bash
<< 'EOF'
Utility functions for IPv4 networking/transformations

USAGE:
        ./iptx.sh <CIDR_address>

OPTIONS:
       [ -h ]              Print usage

EXAMPLES:
        ./iptx.sh 128.42.5.4/21          # get printout summary

DESCRIPTION:

* __valid_ipv4()     : check if an IPv4 address is valid or not.
* __valid_cidr()     : check if CIDR notation is valid or not.
* __ip2bin()         : convert an IPv4 address from dotted-decimal notation to binary.
* __bin2ip()         : convert an IPv4 address from binary to dotted-decimal notation.
* __cidr2netmask()   : extract the netmask from an IPv4 address given in CIDR notation.
* __cidr2network()   : extract the network address from a CIDR IPv4 address.
* __cidr2broadcast() : extract the broadcast address from a CIDR IPv4 address.
* __cidr2numhosts()  : extract the number of hosts that can be assigned IP addresses.
* __cidr2ipfirst()   : extract the first usable IP address from CIDR notation.
* __cidr2iplast()    : extract the last usable IP address from CIDR notation.

EXAMPLES:

__ip2bin 128.42.5.4                             # 10000000 00101010 00000101 00000100
__bin2ip '10000000;00101010;00000101;00000100'  # 128.42.5.4

./iptx.sh 128.42.5.4/21

Network address        : 128.42.0.0
Broadcast address      : 128.42.7.255
Subnet mask            : 255.255.248.0
First usable address   : 128.42.0.1
Last usable address    : 128.42.7.254
Number of usable hosts : 2046

EOF

__print_usage        () { :; }  # print usage
__valid_ipv4         () { :; }  # Is IPv4 address valid?
__valid_cidr         () { :; }  # Is CIDR address valid?
__zero_pad           () { :; }  # zero pad
__ip2bin             () { :; }  # IPv4 (decimal-dotted) to binary
__bin2ip             () { :; }  # binary to IPv4 (decimal-dotted)
__get_ip             () { :; }  # get IP address from CIDR
__get_netmask_length () { :; }  # get netmask length from CIDR
__get_host_length    () { :; }  # get host length from CIDR
__get_network_part   () { :; }  # get network part (binary)
__cidr2netmask       () { :; }  # CIDR to netmask address
__cidr2network       () { :; }  # CIDR to network address
__cidr2broadcast     () { :; }  # CIDR to broadcast address
__cidr2numhosts      () { :; }  # CIDR to number of hosts
__cidr2ipfirst       () { :; }  # CIDR to first usable IP address
__cidr2iplast        () { :; }  # CIDR to last usable IP address
__parse_arguments    () { :; }  # parse arguments
__validate_arguments () { :; }  # check if arguments are valid
__print_tx           () { :; }  # print transformations
__main               () { :; }  # main function

__print_usage() {
    echo -e "iptx.sh: utility for CIDR to IPv4 transformations.

    Usage:
           ./${0##*/} 128.42.5.4/21

           . ./${0##*/}
           __cidr2network 128.42.5.4/21
           __cidr2broadcast 128.42.5.4/21 \n"
}

__valid_ipv4() {
    local ip="${1}"
    [[ "${ip}" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]

    if [ "$?" -ne 0 ]; then
        echo "Invalid Ipv4 address. Exiting..."
        exit 1
    fi
}

__valid_cidr() {
    local ip_cidr="${1}"

    if [[ "${ip_cidr}" =~ ^[^/]*/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
        ip=$(echo "${ip_cidr}" | cut -d '/' -f 1)
        __valid_ipv4 "${ip}"
    else
        echo "Invalid CIRD address. Exiting..."
        exit 1
    fi
}

# example: 110 > 00000110
__zero_pad() {
    local input="${1}"
    n="$(expr length "${input}")"
    z=""

    if [ "$n" -lt 8 ]; then
        d=$((8-n))
        z="$(head -c "$d" /dev/zero | tr '\0' '0')"
    fi
    echo "${z}${input}"
}

# example: 128.42.5.4 > 10000000 00101010 00000101 00000100
__ip2bin() {
    local ip="${1}"
    x="$(echo "${ip}" | tr '.' ';')"
    r="$(echo "obase=2; ibase=10; ${x}" | bc)"
    for i in $r; do __zero_pad "${i}"; done | xargs
}

# example: '10000000;00101010;00000101;00000100' > 128.42.5.4
__bin2ip() {
    local binary_sequence="${1}"
    echo "obase=10; ibase=2; ${binary_sequence}" | bc | xargs | tr ' ' '.'
}

__get_ip() {
    ip="$(echo "${ip_cidr}" | awk -F '/' '{print $1}')"
}

__get_netmask_length() {
    netmask_length="$(echo "${ip_cidr}" | awk -F '/' '{print $2}')"
}

__get_host_length() {
    host_length="$((32 - netmask_length))"
}

__get_network_part() {
    ip_bin="$(__ip2bin "$ip" | tr -d ' ')"
    network_part="$(echo "${ip_bin:0:netmask_length}")"
}

# example: 128.42.5.4/21 > 255.255.248.0
__cidr2netmask() {
    ones="$(head -c "${netmask_length}" /dev/zero | tr '\0' '1')"
    zeros="$(head -c "${host_length}" /dev/zero | tr '\0' '0')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${ones}${zeros}")"
    netmask="$(__bin2ip "${sequence}")"
}

# example: 128.42.5.4/21 > 128.42.0.0
__cidr2network() {
    zeros="$(head -c "${host_length}" /dev/zero | tr '\0' '0')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${zeros}")"
    network="$(__bin2ip "${sequence}")"
}

# example: 128.42.5.4/21 > 128.42.7.255
__cidr2broadcast() {
    ones="$(head -c "${host_length}" /dev/zero | tr '\0' '1')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${ones}")"
    broadcast="$(__bin2ip "${sequence}")"
}

# example: 128.42.5.4/21 > 2046 (number of usable hosts)
__cidr2numhosts() {

    if [[ "${host_length}" -eq 0 ]]; then
        numhosts="0"
    else
        numhosts="$((2**host_length - 2))"
    fi
}

# example: 128.42.5.4/21 > 128.42.0.1 (first usable IP address)
__cidr2ipfirst() {

    if [ "${host_length}" -le 1 ]; then
        ipfirst="None"
    else
        zeros="$(head -c "$((host_length-1))" /dev/zero | tr '\0' '0')"
        sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${zeros}1")"
        ipfirst="$(__bin2ip "${sequence}")"
    fi
}

# example: 128.42.5.4/21 > 128.42.7.254 (last usable IP address)
__cidr2iplast() {

    if [ "${host_length}" -le 1 ]; then
        iplast="None"
    else
        ones="$(head -c "$((host_length-1))" /dev/zero | tr '\0' '1')"
        sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${ones}0")"
        iplast="$(__bin2ip "${sequence}")"
    fi
}

__parse_arguments() {
    args=()
    while (("$#")); do
        case "$1" in
            -h | --help ) __print_usage; exit 0;;
            -*          ) echo "Invalid option. Exiting..."; exit 1;;
            *           ) args+=("$1"); shift;;
        esac
    done
}

__validate_arguments() {

    if [[ "${#args[@]}" -ne 1 ]]; then
        echo "Number of arguments should be 1. Exiting..."
        exit 1
    fi

    ip_cidr="${args[0]}"

    __valid_cidr "${ip_cidr}"
}

__print_tx() {
    echo "Network address        : $network"
    echo "Broadcast address      : $broadcast"
    echo "Subnet mask            : $netmask"
    echo "First usable address   : $ipfirst"
    echo "Last usable address    : $iplast"
    echo "Number of usable hosts : $numhosts"
}

__main() {
    __parse_arguments "$@"
    __validate_arguments

    __get_ip
    __get_netmask_length
    __get_host_length
    __get_network_part

    __cidr2network
    __cidr2broadcast
    __cidr2netmask
    __cidr2ipfirst
    __cidr2iplast
    __cidr2numhosts

    __print_tx
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
