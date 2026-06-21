#!/usr/bin/env bash

<< 'EOF'
Check host and Swarm services
  * Check Docker service is running
  * Check NFS service is running
  * Check disk space is not full
  * Check Swarm services
    * List scaled down services
    * List services that are down (i.e., unstable/flipping)
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

__set_color() {
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    default="$(tput sgr0)"
}

__check_docker_service() {
    __set_color

    echo -e "Checking Docker service...\n"

    systemctl is-active docker.service &> /dev/null

    if [[ "$?" -eq 0 ]]; then
        echo -e "[ ${green}OK${default} ] Docker service is active.\n"
    else
        echo -e "[ ${red}ERROR${default} ] Docker service is down.\n"
    fi
}

__check_nfs_service() {
    __set_color

    echo -e "Checking NFS service...\n"

    dpkg -s nfs-kernel-server &> /dev/null

    if [[ "$?" -eq 0 ]]; then
        systemctl is-active docker.service &> /dev/null

        if [[ "$?" -eq 0 ]]; then
            echo -e "[ ${green}OK${default} ] NFS service is active.\n"
        else
            echo -e "[ ${red}ERROR${default} ] NFS service is down.\n"
        fi
    else
        echo -e "[ ${green}OK${default} ] This node is an NFS client.\n"
    fi
}

__check_disk_space() {
    __set_color

    echo -e "Checking disk space...\n"

    disk_full="$(df -h | awk '$5 == "100%"')"

    if [[ -z "$disk_full" ]]; then
        echo -e "[ ${green}OK${default} ] Disk is not full.\n"
    else
        echo -e "[ ${red}ERROR${default} ] Disk is full.\n"
        echo -e "${disk_full}\n"
    fi
}

__check_swarm_manager() {
    echo -e "Checking Swarm services...\n"

    docker node ls &> /dev/null

    if [[ "$?" -eq 0 ]]; then
        echo -e "[ ${green}OK${default} ] Node is a Swarm manager.\n"
    else
        echo -e "[ ${red}ERROR${default} ] Node is not a Swarm manager.\n"
        exit 0
    fi
}

__list_scaled_down_services() {
    echo -e "Checking scaled down services...\n"

    docker service ls | awk '$4 ~ /.*\/0/'
}

__list_services_down() {
    echo -e "Checking services that are down/flipping...\n"

    > services_down

    for i in {1..20}; do
        echo -n "$((21 - i)).."
        docker service ls | awk '$4 ~ /0\/[1-9][0-9]*/' >> services_down
        sleep 1
    done

    echo -e "\n"

    if [[ -z "$(cat services_down)" ]]; then
        echo -e "[ ${green}OK${default} ] All services are up.\n"
    else
        echo -e "[ ${red}ERROR${default} ] List of services down/flipping:\n"
        sort -u services_down
    fi
}

__check_swarm_services() {
    __check_swarm_manager
    __list_scaled_down_services
    __list_services_down
}

__main() {
    __parse_options "$@"
    __check_euid
    __check_docker_service
    __check_nfs_service
    __check_disk_space
    __check_swarm_services
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
