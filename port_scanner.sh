#!/usr/bin/env bash

<< 'EOF'
Script that checks whether a list of TCP ports are open on a given host.

For each port, it attempts to connect using nc with a short timeout (2 seconds).

It prints whether each port is open or closed.

Example Usage:

./port_scanner.sh google.com 80,443,8080

Port 80 - OPEN
Port 443 - OPEN
Port 8080 - CLOSED
EOF

__print_usage        () { :; }
__parse_options      () { :; }
__check_nargs        () { :; }
__parse_arguments    () { :; }
__validate_arguments () { :; }
__check_nc_installed () { :; }
__check_ports        () { :; }
__print_result       () { :; }
__main               () { :; }

__print_usage() {
    echo -e "Port Scanner.
 
             USAGE:
                   ./${0##*/} <hostname_or_ip_address> <port_number(s)>
                   ./${0##*/} google.com 80,443,8080
                   ./${0##*/} localhost 21,22 \n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage; exit 0;;
            *) echo "Invalid option. Exiting..."; exit 1;;
       esac
    done
}

__check_nargs() {
    if [ "$#" -ne 2 ]; then
        echo "Invalid number of arguments. Exiting..."
        __print_usage
        exit 1
    fi
}

__parse_arguments() {
    target="$1"
    ports="$2"
}

__validate_arguments() {
    IFS=',' ports_list="$ports"

    ports_array=($ports_list)

    for port in "${ports_array[@]}"; do
        if ! [[ "$port" =~ ^[1-9][0-9]*$ ]]; then
            echo "Port number '$port' is not a positive integer. Exiting..."
            exit 1
        fi
    done
}

__check_nc_installed() {
    if [ -z "$(which nc)" ]; then
        echo "nc (netcat) is not installed. Install it to use the script. Exiting..."
        exit 1
    fi
}

__check_ports() {
    status=()
    for port in "${ports_array[@]}"; do
        nc -z -w 2 "$target" "$port"
        if [ "$?" -eq 0 ]; then
            status+=("OPEN")
        else
            status+=("CLOSED")
        fi
    done
}

__print_result() {
    for i in "${!ports_array[@]}"; do
        echo "Port ${ports_array[i]} - ${status[i]}"
    done
}

__main() {
    __parse_options "$@"
    __check_nargs "$@"
    __parse_arguments "$@"
    __validate_arguments
    __check_nc_installed
    __check_ports
    __print_result
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
