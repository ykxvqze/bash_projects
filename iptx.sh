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

* valid_ipv4() checks if an IPv4 address is valid or not.
* ip2bin() converts an IPv4 address from decimal-dotted notation to binary.
* bin2ip() convertes an IPv4 address from binary to decimal-dotted notation.
* cidr2netmask() extracts the netmask from an IPv4 address given in CIDR notation.
* cidr2network() extracts the network address from a CIDR IPv4 address.
* cidr2broadcast() extracts the broadcast address from a CIDR IPv4 address.

EXAMPLE:

ip2bin 128.42.5.4  # 10000000 00101010 00000101 00000100
bin2ip '10000000 00101010 00000101 00000100'  # 128.42.5.4
cidr2network 128.42.5.4/21    # 128.42.0.0
cidr2netmask 128.42.5.4/21    # 55.255.248.0 
cidr2broadcast 128.42.5.4/21  # 128.42.7.255

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

    if [ $? -eq 0 ]; then
        OIFS=$IFS; IFS='.'
        ip=($ip)
        IFS=$OIFS
    
        [ ${ip[0]} -le 255 -a ${ip[1]} -le 255 -a \
          ${ip[2]} -le 255 -a ${ip[3]} -le 255 ]

        status=$?
    fi
    return $status
}

# Example: 128.42.5.4 --> 10000000 00101010 00000101 00000100
ip2bin() {
    local ip="$1"
    x=`echo $ip | tr '.' ';'`
    r=`echo "ibase=10; obase=2; $x" | bc`
    for i in $r; do zero_pad $i; done | xargs
}

# Example: '10000000 00101010 00000101 00000100' --> 128.42.5.4 
bin2ip() {
    local b="$1"
    for i in $b; do 
        echo "obase=10; ibase=2; $i" | bc
    done | xargs | tr ' ' '.'
}

# Example: 110 --> 00000110 
zero_pad(){
    local input="$1"
    local z
    n=`expr length $input`
    
    if [ $n -lt 8 ]; then
	d=$((8-n))
        z=`head -c $d /dev/zero | tr '\0' '0'`
    fi
    echo ${z}${input}
}

# Example: 128.42.5.4/21 --> 255.255.248.0 
cidr2netmask(){
    local ip_cidr="$1"
    netmask_length=`echo "${ip_cidr}" | cut -d '/' -f 2`
    d=$((32-netmask_length))
    ones=`head -c "${netmask_length}" /dev/zero | tr '\0' '1'`
    zeros=`head -c "$d" /dev/zero | tr '\0' '0'`
    sequence=`sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1 \2 \3 \4/' <<< ${ones}${zeros}`
    bin2ip "$sequence"
}

# Example: 128.42.5.4/21 -->  128.42.0.0
cidr2network(){
    local ip_cidr="$1"
    local netmask_length=`echo "${ip_cidr}" | cut -d '/' -f 2`
    local ip=`echo ${ip_cidr} | cut -d '/' -f 1`
    local network_address=`ip2bin "$ip" | tr -d ' '`

    network_address=`grep -Eo '.' <<< "$network_address"`
    network_address=($network_address)

    for i in `seq 1 32`; do
         if [ $i -gt ${netmask_length} ]; then
             network_address[$((i-1))]=0
         fi
    done

    network_address=`echo ${network_address[@]} | tr -d ' '`
    sequence=`sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1 \2 \3 \4/' <<< ${network_address}`

   bin2ip "$sequence"
}

# Example: 128.42.5.4/21 --> 128.42.7.255
cidr2broadcast(){
    local ip_cidr="$1"
    local netmask_length=`echo "${ip_cidr}" | cut -d '/' -f 2`
    local ip=`echo ${ip_cidr} | cut -d '/' -f 1`
    local broadcast_address=`ip2bin "$ip" | tr -d ' '`

    broadcast_address=`grep -Eo '.' <<< "$broadcast_address"`
    broadcast_address=($broadcast_address)

    for i in `seq 1 32`; do
         if [ $i -gt ${netmask_length} ]; then
             broadcast_address[$((i-1))]=1
         fi
    done

    broadcast_address=`echo ${broadcast_address[@]} | tr -d ' '`
    sequence=`sed -E 's/(.{8})(.{8})(.{8})(.{8})/\1 \2 \3 \4/' <<< ${broadcast_address}`

   bin2ip "$sequence"
}
