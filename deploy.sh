#!/usr/bin/env bash

<< 'EOF'
A script to deploy a project to a remote server via SSH

USAGE: ./deploy.sh [ -p <dir> ] [ -c <file> ]

OPTIONS:
       [ -h ]           Print usage and exit
       [ -p <dir> ]     Specify project directory (if unspecified, defaults to the current working directory)
       [ -c <file> ]    Specify configuration file (defaults to "deploy.conf" in the project directory)

OUTPUT:
       N/A

DESCRIPTION:

For each target specified in the configuration file, the script packs
the local directory into a gzipped tarball, copies it to the /tmp directory
of the remote host via scp, and unpacks the tar file to the remote directory
specified in the configuration file.

NOTE:

The host, the local directory of the project, and the remote directory are
specified in the configuration file (deploy.conf). Each line in the file
corresponds to a single deployment.
EOF

set -eo pipefail

__print_usage       () { :; }
__parse_options     () { :; }
__get_abs_paths     () { :; }
__create_temp_files () { :; }
__cleanup           () { :; }
__set_trap          () { :; }
__read_config_file  () { :; }
__deploy_targets    () { :; }
__main              () { :; }

__print_usage() {
    echo -e "deploy.sh: Deployment script

    Usage: ./${0##*/} [ -p <dir> ] [ -c <file> ] [ -h ]

    [ -p <dir>  ]    Specify project directory (defaults to current working directory if omitted)
    [ -c <file> ]    Specify configuration file (defaults to 'deploy.conf' in the project directory)
    [ -h ]           Print usage and exit \n"
}

__parse_options() {
    while getopts "p:c:h" option; do
        case "$option" in
            p) dir_project="$OPTARG" ;;
            c) file_config="$OPTARG" ;;
            h) __print_usage; exit 0 ;;
            *) __print_usage; exit 1 ;;
        esac
    done
}

__get_abs_paths() {
    if [[ -n "${dir_project}" ]]; then
        dir_project=$(realpath "${dir_project}")
    else
        dir_project="$(pwd)"
    fi

    if [[ -z "${file_config}" ]]; then
        file_config="${dir_project}/deploy.conf"
    fi
}

__create_temp_files() {
    dir_temp="$(mktemp -d /tmp/deploy.$$.XXXXXX)"
    file_archive="$dir_temp/file.tgz"
}

__cleanup() {
    if [[ -f "${file_archive}" ]]; then
        rm "${file_archive}"
    fi

    if [[ -d "${dir_temp}" ]]; then
        rm -rf "${dir_temp}"
    fi
}

__set_trap() {
    trap "__cleanup" EXIT SIGINT SIGTERM
}

__read_config_file() {
    config=$(<${file_config})
    config="$(echo "${config}" | sed '/^$/d' | grep -v '^#')"
}

__deploy_targets() {
    n_target="$(echo "${config}" | wc -l)"

    for ((i=1; i<=n_target; i++)); do
        target="$(echo "${config}" | sed -n "${i} p")"
        host="$(echo "$target" | awk '{print $2}')"
        dir_local="$(echo "$target" | awk '{print $3}')"
        dir_remote="$(echo "$target" | awk '{print $4}')"

        printf '%s\n' "Project          : ${dir_project}"
        printf '%s\n' "Host             : ${host}"
        printf '%s\n' "Local Directory  : ${dir_local}"
        printf '%s\n' "Remote Directory : ${dir_remote}"

        if [[ -z "${dir_local}" ]]; then
            echo 'No directory to deploy'
            exit 1
        fi

        if [[ -z "${dir_remote}" ]]; then
            echo 'No remote directory specified'
            exit 1
        fi

        if [[ -z "${host}" ]]; then
            echo 'No host specified'
            exit 1
        fi

        # create tar archive
        echo -n "Packing... "
        tar -C "${dir_project}/${dir_local}" -czf "${file_archive}" .

        # copy tar file to remote system
        echo -n "Transferring... "
        scp -i ~/.ssh/id_rsa "${file_archive}" "$host:/tmp/file.tgz"
        echo "Transferred."

        # unpack and delete tar file
        echo -n "Unpacking... "
        ssh -i ~/.ssh/id_rsa "$host" "tar -C ${dir_remote} -xzf /tmp/file.tgz ; rm -f /tmp/file.tgz"
        echo "Unpacked."

        echo "Done"
    done
}

__main() {
    __set_trap
    __parse_options "$@"
    __get_abs_paths
    __create_temp_files
    __read_config_file
    __deploy_targets
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
