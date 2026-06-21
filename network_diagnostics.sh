#!/usr/bin/env bash

<< 'EOF'
* List interfaces and their status
* List routing table
* List DNS nameservers
* Get ping status by IP
* Get ping status by hostname
* Check VPN route
* Check wireguard client-server handshake
EOF

__print_usage() {
    echo -e "\nUsage: sudo ./${0##*/} \n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h ) __print_usage; exit 0;;
            * ) echo "Invalid option. Exiting..."; exit 1;;
        esac
    done
}

__check_euid() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Run script with sudo privilege."
        __print_usage
        exit 1
    fi
}

__list_interface_info() {
    interfaces=( $(nmcli | grep -E '^wl|^en' | cut -d ':' -f 1) )

    interfaces_wg=( $(nmcli | grep -B 2 'wireguard' | head -1 | cut -d ':' -f 1) )

    interfaces+=( ${interfaces_wg[@]} )

    interface_status=( $(nmcli | grep -E '^wl|^en' | cut -d ' ' -f 2) )

    interface_status_wg=( $(nmcli | grep -B 2 'wireguard' | head -1 | cut -d ' ' -f 2) )

    interface_status+=( ${interface_status_wg[@]} )

    echo -e "Interfaces:\n"

    for i in ${!interfaces[@]}; do
        sw_disabled_status="$(nmcli | grep -E -A 2 "${interfaces[i]}" | grep -Eo 'sw disabled')"
        ip_address="$(ip -o -4 a | grep "${interfaces[i]}" | awk '{print $4}' | sed 's/\/.*//')"
        gateway="$(ip route | grep "${interfaces[i]}" | grep 'default' | awk '{print $3}')"

        echo -e "${interfaces[i]}"
        echo -e "\t${interface_status[i]}. ${sw_disabled_status}"
        echo -e "\tIP address: ${ip_address}"
        echo -e "\tGateway: ${gateway}\n"
    done
}

__list_routing_table() {
    echo -e "Routing table:\n"
    echo -e "$(ip route)\n"
}

__list_dns_nameservers() {
    resolvectl status | grep 'Current DNS Server' | sed -E 's/^\s+//'
}

__get_ping_status_by_ip() {
    ping -c 1 -W 1 8.8.8.8 &> /dev/null

    if [[ "$?" -eq 0 ]]; then
        echo -e "[ OK ] ping $(ip route get 8.8.8.8 | sed '$d' | cut -d ' ' -f 1-5) succeeded.\n"
    else
        echo -e "[ ERROR ] ping $(ip route get 8.8.8.8 | sed '$d' | cut -d ' ' -f 1-5) failed.\n"
    fi
}

__get_ping_status_by_hostname() {
    ping -c 1 -W 1 www.google.com &> /dev/null

    if [[ "$?" -eq 0 ]]; then
        echo -e "[ OK ] ping www.google.com succeeded.\n"
    else
        echo -e "[ ERROR ] ping www.google.com failed.\n"
    fi
}

__check_vpn_route() {
    ping -c 1 -W 1 192.168.40.7 &> /dev/null

    if [[ "$?" -eq 0 ]]; then
        echo -e "[ OK ] ping $(ip route get 192.168.40.7 | sed '$d' | cut -d ' ' -f 1-5) succeeded.\n"
    else
        echo -e "[ ERROR ] ping $(ip route get 192.168.40.7 | sed '$d' | cut -d ' ' -f 1-5) failed.\n"
    fi
}

__check_wg_handshake() {
    dpkg -l | grep wireguard-tools &> /dev/null

    if [[ "$?" -ne 0 ]]; then
        apt-get install wireguard-tools &> /dev/null
    fi

    if [[ -z "$(wg show)" ]]; then
        echo -e "[ ERROR ] wireguard connection is off.\n"
    else
        handshake_status="$(wg show | grep 'handshake')"

        if [[ -z "$handshake_status" ]]; then
            echo -e "[ ERROR ] No wg handshake detected. Wireguard server issue.\n"
        else
            echo -e "[ OK ] wg handshake detected: ${handshake_status}.\n"
        fi
    fi
}

__main() {
    __parse_options "$@"
    __check_euid
    __list_interface_info
    __list_routing_table
    __list_dns_nameservers
    __get_ping_status_by_ip
    __get_ping_status_by_hostname
    __check_vpn_route
    __check_wg_handshake
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
