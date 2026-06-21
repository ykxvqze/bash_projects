#!/usr/bin/env bash

<< 'EOF'
Check disk space across dev-std, dev-pro, test-std, test-pro, and services.
EOF

__check_instance() {
    host="$1"
    ssh -o StrictHostKeyChecking=no "$host" "remote_host=$host bash -s" << 'EOF'
        data="$(df -h)"
        row_indices="$(echo "$data" | cat -n | awk 'NR > 1 {print $1,$6}' | sed -E 's/%$//' | awk '$2 >= 80 {print $1}')"
        echo -e "\n$remote_host: \n"
        if [[ -n "$row_indices" ]]; then
            echo "$data" | sed -n '1 p'
            for i in $row_indices; do
                echo "$data" | sed -n "$i p"
                echo
            done
        fi
EOF
}

__check_disk_space() {
    instances=('dev-std1' 'dev-std2' 'dev-pro1' 'dev-pro2' 'test-std1' 'test-std2' 'test-pro1' 'test-pro2' 'services')

    for instance in ${instances[@]}; do
        __check_instance "$instance"
        sleep 1
    done
}

__main() {
    __check_disk_space
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main
fi
