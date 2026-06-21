#!/usr/bin/env bash

<< 'EOF'
Identify modsecurity 403 errors in nginx logs and show remediation steps.
EOF

__print_usage() {
    echo -e "Identify modsecurity 403 errors in nginx logs.

             USAGE:
                   ./${0##*/} \n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h ) __print_usage; exit 0;;
            * ) echo "Invalid option. Exiting..."; exit 1;;
        esac
    done
}

__get_nginx_container_id() {
    echo -e "Checking for nginx containers...\n"
    nginx_container_id="$(docker ps | grep 'nginx-waf' | awk '{print $1}')"

    if [[ -z "$nginx_container_id" ]]; then
        echo "No nginx container found. Exiting..."
        exit 1
    elif [[ "$(echo "$nginx_container_id" | wc -l)" -gt 1 ]]; then
        echo "More than one nginx container found. Exiting..."
        exit 1
    else
        echo -e "nginx-waf container id: $nginx_container_id \n"
    fi
}

__get_error_log() {
    error_log="$(docker exec "$nginx_container_id" cat /var/log/nginx/error.log)"
}

__filter_error_log() {
    timestamps="$(echo "$error_log" | grep 'ModSecurity: Access denied with code 403' | awk '{print $1,$2}')"
    URIs="$(echo "$error_log" | grep 'ModSecurity: Access denied with code 403' | grep -Eo 'uri "[^"]+"' | tr -d '"' | sed -E 's/uri//; s/\s+//')"
    errors="$(paste <(echo "$timestamps") <(echo "$URIs"))"
    number_of_errors="$(echo "$errors" | wc -l)"
}

__set_color() {
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    default="$(tput sgr0)"
}

__print_403_errors_with_remediation() {
    __set_color

    echo -e "ModSecurity: Access denied with code 403:\n"

    for ((i=1; i <= number_of_errors; i++)); do
        error_line="$(echo "$errors" | sed -n "$i p")"
        uri="$(echo "$errors" | sed -n "$i p" | awk '{print $NF}')"
        echo -e "[$i] ${red}${error_line}${default}"
        echo -e "\n${green}SecRule REQUEST_URI \"@beginsWith $uri\" \\
        \"id:XXXX,phase:1,pass,nolog,ctl:ruleEngine=Off\"${default} \n"
    done

    echo -e "Reload nginx configurations:\n"
    echo -e "${green}docker exec $nginx_container_id nginx -t ${default}"
    echo -e "${green}docker exec $nginx_container_id nginx -s reload ${default}"
}

__main() {
    __parse_options "$@"
    __get_nginx_container_id
    __get_error_log
    __filter_error_log
    __print_403_errors_with_remediation
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
