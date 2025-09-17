#!/usr/bin/env bash

<< 'EOF'

Random web traffic generator - kill process w/ Ctrl+C to end the script

EOF

__print_usage       () { :; }
__parse_options     () { :; }
__check_config_file () { :; }
__load_root_urls    () { :; }
__load_user_agents  () { :; }
__set_max_depth     () { :; }
__choose_item       () { :; }
__fetch_url         () { :; }
__get_child_urls    () { :; }
__set_trap          () { :; }
__run_crawler       () { :; }
__main              () { :; }

__print_usage() {
    echo -e "
    Random web traffic generator - kill process w/ Ctrl+C to end the script

    USAGE:
          ./${0##*/} \n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage; exit 0;;
            *) echo "Invalid option. Exiting..."; exit 1;;
        esac
    done
}

__check_config_file() {
    src_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")" )"
    config_file="$src_dir"/config.json
    if [[ ! -f "${config_file}" ]]; then
        echo "Could not find 'config.json'. Exiting ..."
        exit 1
    fi
}

__load_root_urls() {
    export root_urls=$(jq '.root_urls' "${config_file}" |
                       grep -o '"[^"]*"'                |
                       grep -o '[^"]*')
}

__load_user_agents() {
    export user_agents=$(jq '.user_agents' "${config_file}" |
                         grep -o '"[^"]*"'                  |
                         grep -o '[^"]*')
}

__set_max_depth() {
    export max_depth="$1"
}

__choose_item() {
    local items="${1}"
    n_items=$(echo "${items}" | wc -l)
    line_number=$(shuf -i 1-${n_items} -n 1)
    item=$(echo "${items}" | sed -n "${line_number} p")
    echo "${item}"
}

__fetch_url() {
    user_agent=$(__choose_item "${user_agents}")
    times=$(seq 0 9)
    time=$(__choose_item "${times}")

    sleep 1."$time"  # in [1.0-1.9]

    echo "[*] URL: ${url}"
    echo "[-] USER AGENT: ${user_agent}"

    wget -O ./file_html -q \
         -e robots=off \
         -np --user-agent="${user_agent}" \
         "${url}"
}

__get_child_urls() {
    blacklist='
    .svg | .jpg | .jpeg | .png  | .tif  | .tiff | .bmp | .gif |
    .iso | .zip | .rar  | .bz2  | .gz   | .tar  | .exe |
    .mp3 | .mp4 | .mpeg | .wma  | .webm | .avi  |
    .css | .ico | .xml  | .json |
    .doc | .xls | .ppt'

    blacklist=$(echo "${blacklist}" | xargs)

    urls=$(cat ./file_html            |
           grep -o 'href="http[^"]*"' |
           grep -o 'http[^"]*'        |
           grep -v "${blacklist}")
}

__set_trap() {
    trap 'rm ./file_html 2>/dev/null; exit' INT TERM EXIT
}

__run_crawler() {
    while :; do
        echo "depth 0 (root URL)..."
        url="$(__choose_item "${root_urls}")"
        __fetch_url
        __get_child_urls

        if [ -z "${urls}" ]; then
            continue
        fi

        for i in $(seq 1 ${max_depth}); do
            echo "depth ${i}..."
            url="$(__choose_item "${urls}")"
            __fetch_url
            __get_child_urls

            if [ -z "${urls}" ]; then
                break
            fi
        done
    done
}

__main() {
    __parse_options "$@"
    __check_config_file
    __load_root_urls
    __load_user_agents
    __set_max_depth 3
    __set_trap
    __run_crawler
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
