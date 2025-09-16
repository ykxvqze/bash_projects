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

* __validate_ipv4()         : check if an IPv4 address is valid or not.
* __validate_cidr()         : check if CIDR notation is valid or not.
* __ip2binary               : convert an IPv4 address from dotted-decimal notation to binary.
* __binary2ip()             : convert an IPv4 address from binary to dotted-decimal notation.
* __get_netmask_address()   : extract the netmask from an IPv4 address given in CIDR notation.
* __get_network_address()   : extract the network address from a CIDR IPv4 address.
* __get_broadcast_address() : extract the broadcast address from a CIDR IPv4 address.
* __get_num_hosts()         : extract the number of hosts that can be assigned IP addresses.
* __get_ip_first()          : extract the first usable IP address from CIDR notation.
* __get_ip_last()           : extract the last usable IP address from CIDR notation.

EXAMPLES:

__ip2binary 128.42.5.4                             # 10000000 00101010 00000101 00000100
__binary2ip '10000000;00101010;00000101;00000100'  # 128.42.5.4

./iptx.sh 128.42.5.4/21

Network address        : 128.42.0.0
Broadcast address      : 128.42.7.255
Subnet mask            : 255.255.248.0
First usable address   : 128.42.0.1
Last usable address    : 128.42.7.254
Number of usable hosts : 2046

EOF

__print_usage             () { :; }  # print usage
__zero_pad                () { :; }  # zero pad
__ip2binary               () { :; }  # IPv4 (decimal-dotted) to binary
__binary2ip               () { :; }  # binary to IPv4 (decimal-dotted)
__get_ipv4                () { :; }  # get IPv4 address from CIDR
__get_netmask_length      () { :; }  # get netmask length from CIDR
__get_host_length         () { :; }  # get host length from CIDR
__get_network_part        () { :; }  # get network part (binary)
__validate_ipv4           () { :; }  # Is IPv4 address valid?
__validate_netmask_length () { :; }  # IS netmask length valid?
__validate_cidr           () { :; }  # Is CIDR address valid?
__get_netmask_address     () { :; }  # get netmask address
__get_network_address     () { :; }  # get network address
__get_broadcast_address   () { :; }  # get broadcast address
__get_num_hosts           () { :; }  # get number of hosts
__get_ip_first            () { :; }  # get first usable IP address
__get_ip_last             () { :; }  # get last usable IP address
__parse_arguments         () { :; }  # parse arguments
__validate_arguments      () { :; }  # check if arguments are valid
__print_tx                () { :; }  # print transformations
__main                    () { :; }  # main function

__print_usage() {
    echo -e "iptx.sh: CIDR to IPv4 transformations.

    Usage:
           ./${0##*/} 128.42.5.4/21 \n"
}

# example: 110 > 00000110
__zero_pad() {
    local pattern="${1}"
    length="$(expr length "${pattern}")"
    zeros=""

    if [ "$length" -lt 8 ]; then
        d=$((8 - length))
        zeros="$(head -c "$d" /dev/zero | tr '\0' '0')"
    fi
    echo "${zeros}${pattern}"
}

# example: 128.42.5.4 > 10000000 00101010 00000101 00000100
__ip2binary() {
    local ip="$1"
    x="$(echo "${ip}" | tr '.' ';')"
    r="$(echo "obase=2; ibase=10; ${x}" | bc)"
    for pattern in $r; do __zero_pad "$pattern"; done | xargs
}

# example: '10000000;00101010;00000101;00000100' > 128.42.5.4
__binary2ip() {
    local binary="$1"
    echo "obase=10; ibase=2; ${binary}" | bc | xargs | tr ' ' '.'
}

__get_ipv4() {
    ipv4="$(echo "${ip_cidr}" | awk -F '/' '{print $1}')"
}

__get_netmask_length() {
    netmask_length="$(echo "${ip_cidr}" | awk -F '/' '{print $2}')"
}

__get_host_length() {
    host_length="$((32 - netmask_length))"
}

__get_network_part() {
    ip_binary="$(__ip2binary "$ipv4" | tr -d ' ')"
    network_part="$(echo "${ip_binary:0:netmask_length}")"
}

__validate_ipv4() {
    if [[ ! "${ipv4}" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
        echo "Invalid IPv4 address. Exiting..."
        exit 1
    fi
}

__validate_netmask_length() {
    if [[ ! "${netmask_length}" =~ ^([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
        echo "Invalid netmask length. Exiting..."
        exit 1
    fi
}

__validate_cidr() {
    if [[ "${ip_cidr}" =~ ^(.*)/(.*)$ ]]; then
        ipv4="${BASH_REMATCH[1]}"
        netmask_length="${BASH_REMATCH[2]}"
        __validate_ipv4
        __validate_netmask_length
    else
        echo "Invalid CIDR address. Exiting..."
        exit 1
    fi
}

# example: 128.42.5.4/21 > 255.255.248.0
__get_netmask_address() {
    ones="$(head -c "${netmask_length}" /dev/zero | tr '\0' '1')"
    zeros="$(head -c "${host_length}" /dev/zero | tr '\0' '0')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${ones}${zeros}")"
    netmask_address="$(__binary2ip "${sequence}")"
}

# example: 128.42.5.4/21 > 128.42.0.0
__get_network_address() {
    zeros="$(head -c "${host_length}" /dev/zero | tr '\0' '0')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${zeros}")"
    network_address="$(__binary2ip "${sequence}")"
}

# example: 128.42.5.4/21 > 128.42.7.255
__get_broadcast_address() {
    ones="$(head -c "${host_length}" /dev/zero | tr '\0' '1')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${ones}")"
    broadcast_address="$(__binary2ip "${sequence}")"
}

# example: 128.42.5.4/21 > 2046 (number of usable hosts)
__get_num_hosts() {
    if [[ "${host_length}" -eq 0 ]]; then
        num_hosts="0"
    else
        num_hosts="$((2**host_length - 2))"
    fi
}

# example: 128.42.5.4/21 > 128.42.0.1 (first usable IP address)
__get_ip_first() {
    if [ "${host_length}" -le 1 ]; then
        ip_first="None"
    else
        zeros="$(head -c "$((host_length-1))" /dev/zero | tr '\0' '0')"
        sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${zeros}1")"
        ip_first="$(__binary2ip "${sequence}")"
    fi
}

# example: 128.42.5.4/21 > 128.42.7.254 (last usable IP address)
__get_ip_last() {
    if [ "${host_length}" -le 1 ]; then
        ip_last="None"
    else
        ones="$(head -c "$((host_length-1))" /dev/zero | tr '\0' '1')"
        sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${ones}0")"
        ip_last="$(__binary2ip "${sequence}")"
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
    __validate_cidr
}

__print_tx() {
    echo "Network address        : ${network_address}"
    echo "Broadcast address      : ${broadcast_address}"
    echo "Subnet mask            : ${netmask_address}"
    echo "First usable address   : ${ip_first}"
    echo "Last usable address    : ${ip_last}"
    echo "Number of usable hosts : ${num_hosts}"
}

__main() {
    __parse_arguments "$@"
    __validate_arguments
    __get_ipv4
    __get_netmask_length
    __get_host_length
    __get_network_part
    __get_network_address
    __get_broadcast_address
    __get_netmask_address
    __get_ip_first
    __get_ip_last
    __get_num_hosts
    __print_tx
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
