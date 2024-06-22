#!/usr/bin/env bash
<< 'EOF'
Utility functions for IPv4 networking/transformations

USAGE: . ./iptx.sh
       cidr2network 128.42.5.4/21
       cidr2broadcast 128.42.5.4/21

       ./iptx.sh 128.42.5.4/21

OPTIONS:
       [ -h ]              Print usage

EXAMPLES:
         . ./iptx.sh                   # source the script
         cidr2network 128.42.5.4/21    # get network address
         cidr2netmask 128.42.5.4/21    # get netmask
         cidr2broadcast 128.42.5.4/21  # get broadcast address
         cidr2ipfirst 128.42.5.4/21    # get first usable IP address
         cidr2iplast 128.42.5.4/21     # get last usable IP address
         cidr2numhosts 128.42.5.4/21   # get number of usable hosts

        ./iptx.sh 128.42.5.4/21        # get printout summary of all info

DESCRIPTION:

* valid_ipv4() - check if an IPv4 address is valid or not.
* valid_cidr() - check if CIDR notation is valid or not.
* ip2bin() - convert an IPv4 address from dotted-decimal notation to binary.
* bin2ip() - convert an IPv4 address from binary to dotted-decimal notation.
* cidr2netmask() - extract the netmask from an IPv4 address given in CIDR notation.
* cidr2network() - extract the network address from a CIDR IPv4 address.
* cidr2broadcast() - extract the broadcast address from a CIDR IPv4 address.
* cidr2numhosts() - extract the number of hosts that can be assigned IP addresses.
* cidr2ipfirst() - extract the first usable IP address from CIDR notation.
* cidr2iplast() - extract the last usable IP address from CIDR notation.

EXAMPLES:

ip2bin 128.42.5.4                             # 10000000 00101010 00000101 00000100
bin2ip '10000000;00101010;00000101;00000100'  # 128.42.5.4
cidr2network 128.42.5.4/21                    # 128.42.0.0
cidr2netmask 128.42.5.4/21                    # 255.255.248.0
cidr2broadcast 128.42.5.4/21                  # 128.42.7.255
cidr2numhosts 128.42.5.4/21                   # 2046
cidr2ipfirst 128.42.5.4/21                    # 128.42.0.1
cidr2iplast 128.42.5.4/21                     # 128.42.7.254

./iptx.sh 128.42.5.4/21

Network address          128.42.0.0
Broadcast address        128.42.7.255
Subnet mask              255.255.248.0
First usable address     128.42.0.1
Last usable address      128.42.7.254
Number of usable hosts   2046

EOF

print_usage    () { :; }  # print usage
valid_ipv4     () { :; }  # Is IPv4 address valid?
valid_cidr     () { :; }  # Is CIDR address valid?
ip2bin         () { :; }  # IPv4 (decimal-dotted) to binary
bin2ip         () { :; }  # binary to IPv4 (decimal-dotted)
cidr2netmask   () { :; }  # CIDR to netmask address
cidr2network   () { :; }  # CIDR to network address
cidr2broadcast () { :; }  # CIDR to broadcast address
cidr2numhosts  () { :; }  # CIDR to number of hosts
cidr2ipfirst   () { :; }  # CIDR to first usable IP address
cidr2iplast    () { :; }  # CIDR to last usable IP address

print_usage() {
    echo -e "iptx.sh: utility for CIDR to IPv4 transformations.
    Usage:
           ./${0##*/} 128.42.5.4/21

           . ./${0##*/}
           cidr2network 128.42.5.4/21
           cidr2broadcast 128.42.5.4/21"
}

valid_ipv4() {
    local ip="${1}"
    [[ "${ip}" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]
    return "$?"
}

valid_cidr() {
    local ip_cidr="${1}"
    local status=1
    if [[ "${ip_cidr}" =~ ^[^/]*/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
        ip=$(echo "${ip_cidr}" | cut -d '/' -f 1)
        valid_ipv4 "${ip}" && status=0
    fi
    return "${status}"
}

# example: 110 --> 00000110
zero_pad() {
    local input="${1}"
    n="$(expr length "${input}")"

    if [ "${n}" -lt 8 ]; then
	    d=$((8-n))
        z="$(head -c "$d" /dev/zero | tr '\0' '0')"
    fi
    echo "${z}${input}"
}

# example: 128.42.5.4 --> 10000000 00101010 00000101 00000100
ip2bin() {
    local ip="${1}"
    x="$(echo "${ip}" | tr '.' ';')"
    r="$(echo "obase=2; ibase=10; ${x}" | bc)"
    for i in $r; do zero_pad "${i}"; done | xargs
}

# example: '10000000;00101010;00000101;00000100' --> 128.42.5.4
bin2ip() {
    local binary_sequence="${1}"
    echo "obase=10; ibase=2; ${binary_sequence}" | bc | xargs | tr ' ' '.'
}

# example: 128.42.5.4/21 --> 255.255.248.0
cidr2netmask() {
    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || return 1
    netmask_length="$(echo "${ip_cidr}" | cut -d '/' -f 2)"
    host_length="$((32-netmask_length))"
    ones="$(head -c "${netmask_length}" /dev/zero | tr '\0' '1')"
    zeros="$(head -c "${host_length}" /dev/zero | tr '\0' '0')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${ones}${zeros}")"
    bin2ip "${sequence}"
}

# example: 128.42.5.4/21 --> 128.42.0.0
cidr2network() {
    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || return 1
    local netmask_length="$(echo "${ip_cidr}" | cut -d '/' -f 2)"
    local ip="$(echo "${ip_cidr}" | cut -d '/' -f 1)"
    local ip_bin="$(ip2bin "$ip" | tr -d ' ')"

    network_part="$(echo "${ip_bin:0:netmask_length}")"
    host_length="$((32-netmask_length))"
    zeros="$(head -c "${host_length}" /dev/zero | tr '\0' '0')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${zeros}")"
    bin2ip "${sequence}"
}

# example: 128.42.5.4/21 --> 128.42.7.255
cidr2broadcast() {
    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || return 1
    local netmask_length="$(echo "${ip_cidr}" | cut -d '/' -f 2)"
    local ip="$(echo ${ip_cidr} | cut -d '/' -f 1)"
    local ip_bin="$(ip2bin "${ip}" | tr -d ' ')"

    network_part="$(echo "${ip_bin:0:netmask_length}")"
    host_length="$((32-netmask_length))"
    ones="$(head -c "${host_length}" /dev/zero | tr '\0' '1')"
    sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${ones}")"
    bin2ip "${sequence}"
}

# example: 128.42.5.4/21 --> 2046 (number of usable hosts)
cidr2numhosts() {
    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || return 1
    netmask_length="$(echo "${ip_cidr}" | cut -d '/' -f 2)"
    host_length="$((32-netmask_length))"
    if [ "${host_length}" -eq 0 ]; then
        echo '0'
    else
        echo "$((2**host_length-2))"
    fi
}

# example: 128.42.5.4/21 --> 128.42.0.1 (first usable IP address)
cidr2ipfirst() {
    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || return 1
    local netmask_length="$(echo "${ip_cidr}" | cut -d '/' -f 2)"
    local ip="$(echo "${ip_cidr}" | cut -d '/' -f 1)"
    local ip_bin="$(ip2bin "${ip}" | tr -d ' ')"

    network_part="$(echo "${ip_bin:0:netmask_length}")"
    host_length="$((32-netmask_length))"
    if [ "${host_length}" -le 1 ]; then
        echo 'None'
    else
        zeros="$(head -c "$((host_length-1))" /dev/zero | tr '\0' '0')"
        sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${zeros}1")"
        bin2ip "${sequence}"
    fi
}

# example: 128.42.5.4/21 --> 128.42.7.254 (last usable IP address)
cidr2iplast() {
    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || return 1
    local netmask_length="$(echo "${ip_cidr}" | cut -d '/' -f 2)"
    local ip="$(echo ${ip_cidr} | cut -d '/' -f 1)"
    local ip_bin="$(ip2bin "$ip" | tr -d ' ')"

    network_part="$(echo "${ip_bin:0:netmask_length}")"
    host_length="$((32-netmask_length))"
    if [ "${host_length}" -le 1 ]; then
        echo 'None'
    else
        ones="$(head -c "$((host_length-1))" /dev/zero | tr '\0' '1')"
        sequence="$(sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1;\2;\3;\4/' <<< "${network_part}${ones}0")"
        bin2ip "${sequence}"
    fi
}

main() {
    while getopts 'h' option; do
        case $option in
            h) print_usage;  exit 0 ;;
            *) print_usage;  exit 1 ;;
        esac
    done

    local ip_cidr="${1}"
    valid_cidr "${ip_cidr}" || exit 1
    {
    echo "Network address        : $(cidr2network ${ip_cidr})"
    echo "Broadcast address      : $(cidr2broadcast ${ip_cidr})"
    echo "Subnet mask            : $(cidr2netmask ${ip_cidr})"
    echo "First usable address   : $(cidr2ipfirst ${ip_cidr})"
    echo "Last usable address    : $(cidr2iplast ${ip_cidr})"
    echo "Number of usable hosts : $(cidr2numhosts ${ip_cidr})"
    } | column -t -s ':'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@}"
fi
