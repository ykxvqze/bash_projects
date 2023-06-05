#!/usr/bin/env bash
<< 'EOF'
Utility functions for IPv4 networking/transformations

USAGE: . ./iptx.sh

OPTIONS:
         N/A

EXAMPLES:
         . ./iptx.sh
         cidr2network 128.42.5.4/21    # get network address
         cidr2netmask 128.42.5.4/21    # get netmask
         cidr2broadcast 128.42.5.4/21  # get broadcast address

DESCRIPTION:

* valid_ipv4() - check if an IPv4 address is valid or not.
* ip2bin() - convert an IPv4 address from decimal-dotted notation to binary.
* bin2ip() - convert an IPv4 address from binary to decimal-dotted notation.
* cidr2netmask() - extract the netmask from an IPv4 address given in CIDR notation.
* cidr2network() - extract the network address from a CIDR IPv4 address.
* cidr2broadcast() - extract the broadcast address from a CIDR IPv4 address.

EXAMPLES:

ip2bin 128.42.5.4                             # 10000000 00101010 00000101 00000100
bin2ip '10000000 00101010 00000101 00000100'  # 128.42.5.4
cidr2network 128.42.5.4/21                    # 128.42.0.0
cidr2netmask 128.42.5.4/21                    # 255.255.248.0
cidr2broadcast 128.42.5.4/21                  # 128.42.7.255

J.A., ykxvqz@pm.me
EOF

valid_ipv4     () { :; }  # Is IPv4 address valid?
ip2bin         () { :; }  # IPv4 (decimal-dotted) to binary
bin2ip         () { :; }  # binary to IPv4 (decimal-dotted)
cidr2netmask   () { :; }  # CIDR to netmask address
cidr2network   () { :; }  # CIDR to network address
cidr2broadcast () { :; }  # CIDR to broadcast address

valid_ipv4() {
    local ip="$1"
    local status=1

    grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$'  <<< "$ip"  &> /dev/null

    if [ "$?" -eq 0 ]; then
        OIFS=$IFS; IFS='.'
        ip=($ip)
        IFS=$OIFS

        [ "${ip[0]}" -le 255 -a "${ip[1]}" -le 255 -a \
          "${ip[2]}" -le 255 -a "${ip[3]}" -le 255 ]

        status="$?"
    fi
    return "$status"
}

valid_cidr() {
    local ip_cidr="$1"
    local status=1

    grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}/([1-9]|[1-2][0-9]|3[0-1])$' <<< "$ip_cidr" &> /dev/null
    if [ "$?" -eq 0 ]; then
        ip=$(echo "${ip_cidr}" | cut -d '/' -f 1)
        valid_ipv4 "$ip"
        if [ "$?" -eq 0 ]; then
            status=0
        fi
    fi 
    return "$status"
}

# Example: 110 --> 00000110
zero_pad(){
    local input="$1"
    local z
    n=`expr length "$input"`

    if [ "$n" -lt 8 ]; then
	    d=$((8-n))
        z=`head -c "$d" /dev/zero | tr '\0' '0'`
    fi
    echo "${z}${input}"
}

# Example: 128.42.5.4 --> 10000000 00101010 00000101 00000100
ip2bin() {
    local ip="$1"
    x=$(echo "$ip" | tr '.' ';')
    r=$(echo "obase=2; ibase=10; $x" | bc)
    for i in $r; do zero_pad "$i"; done | xargs
}

# Example: '10000000 00101010 00000101 00000100' --> 128.42.5.4
bin2ip() {
    local b="$1"
    for i in $b; do
        echo "obase=10; ibase=2; $i" | bc
    done | xargs | tr ' ' '.'
}

# Example: 128.42.5.4/21 --> 255.255.248.0
cidr2netmask(){
    local ip_cidr="$1"
    valid_cidr "$ip_cidr"
    if [ "$?" -ne 0 ]; then
        return 1
    fi
    netmask_length=`echo "${ip_cidr}" | cut -d '/' -f 2`
    d=$((32-netmask_length))
    ones=$(head -c "${netmask_length}" /dev/zero | tr '\0' '1')
    zeros=$(head -c "$d" /dev/zero | tr '\0' '0')
    sequence=`sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1 \2 \3 \4/' <<< "${ones}${zeros}"`
    bin2ip "$sequence"
}

# Example: 128.42.5.4/21 -->  128.42.0.0
cidr2network(){
    local ip_cidr="$1"
    valid_cidr "$ip_cidr"
    if [ "$?" -ne 0 ]; then
        return 1
    fi
    local netmask_length=`echo "${ip_cidr}" | cut -d '/' -f 2`
    local ip=`echo "${ip_cidr}" | cut -d '/' -f 1`
    local ip_bin=`ip2bin "$ip" | tr -d ' '`

    network_part=`echo "${ip_bin:0:netmask_length}"`
    d=$((32-netmask_length))
    zeros=`head -c "$d" /dev/zero | tr '\0' '0'`
    sequence=`sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1 \2 \3 \4/' <<< "${network_part}${zeros}"`
    bin2ip "$sequence"
}

# Example: 128.42.5.4/21 --> 128.42.7.255
cidr2broadcast(){
    local ip_cidr="$1"
    valid_cidr "$ip_cidr"
    if [ "$?" -ne 0 ]; then
        return 1
    fi
    local netmask_length=`echo "${ip_cidr}" | cut -d '/' -f 2`
    local ip=`echo ${ip_cidr} | cut -d '/' -f 1`
    local ip_bin=`ip2bin "$ip" | tr -d ' '`

    network_part=`echo "${ip_bin:0:netmask_length}"`
    d=$((32-netmask_length))
    ones=`head -c "$d" /dev/zero | tr '\0' '1'`
    sequence=`sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1 \2 \3 \4/' <<< "${network_part}${ones}"`
    bin2ip "$sequence"
}
