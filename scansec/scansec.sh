#!/usr/bin/env bash

<< 'EOF'
A script for server security auditing.

USAGE: ./scansec.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
         "OK" or "FAILED"/remediation results in stdout, in addition to
         an audit report saved in the current working directory. The
         report includes OS/kernel information and the audit results.

DESCRIPTION:

scansec.sh checks for several configuration settings relating to system
files and the network. The main audit rules are separated into files and
listed under the ./tests directory. More rules can be added to the files.
The script audits each entry appearing in the files by testing against an
expected output. If there is a match with the expected output, the test
is marked as OK, otherwise it is marked as FAILED (and a remediation step
is listed). In this design, the test files can be expanded independently
to include more rules. The rules are not hard-coded into the main script
itself, which only handles the display.
EOF

__print_usage        () { :; }
__parse_options      () { :; }
__check_euid         () { :; }
__set_colors         () { :; }
__set_audit_report   () { :; }
__print_systeminfo   () { :; }
__include_test_files () { :; }
__run_audit          () { :; }
__print_summary      () { :; }
__main               () { :; }

__print_usage(){
    echo -e "Security auditing

    Usage:
           sudo ./${0##*/}
                ./${0##*/} -h     Print usage and exit\n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage; exit 0;;
            *) echo -e 'Invalid option. Exiting...'; exit 1;;
        esac
    done
}

__check_euid() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e '\nPlease run this script as a privileged user:'
        echo
        echo -e 'sudo ./scansec.sh\n'
        exit 1
    fi
}

__set_colors() {
    DEFAULT='\e[0m'
    RED='\e[31m'
    GREEN='\e[32m'
    YELLOW='\e[33m'
}

__set_audit_report() {
    audit_report="$PWD/audit_report_$(date +'%Y_%m_%d_%H%M%S')"
}

__print_systeminfo() {
    echo ''
    echo -e "[+] ${YELLOW}Operating System Information${DEFAULT}"
    echo "----------------------------------------"
    printf "%s\n" "Operating System         : $(uname -s)"                         | tee -a "${audit_report}"
    printf "%s\n" "Operating System Name    : $(lsb_release -i | sed 's/.*:\s//')" | tee -a "${audit_report}"
    printf "%s\n" "Operating System Version : $(lsb_release -d | sed 's/.*:\s//')" | tee -a "${audit_report}"
    printf "%s\n" "Kernel Version           : $(uname -r)"                         | tee -a "${audit_report}"
    printf "%s\n" "Hardware Platform        : $(uname -m)"                         | tee -a "${audit_report}"
    printf "%s\n" "Hostname                 : $(hostname)"                         | tee -a "${audit_report}"
}

__include_test_files() {
    src_directory="$(dirname ${BASH_SOURCE[0]})"
    includedir="${src_directory}/tests"
    testfiles="$(ls "$includedir")"
}

__run_audit() {
    n_pass=0
    n_fail=0

    find /tmp -maxdepth 1 -name "file.$(basename ${BASH_SOURCE[0]}).*" -delete

    for testfile in $testfiles; do
        echo ''
        echo -e "[+] ${YELLOW}$(sed -n '1 p' ${includedir}/${testfile})${DEFAULT}"
        echo "----------------------------------------"

        filetmp="$(mktemp /tmp/file.$(basename ${BASH_SOURCE[0]}).$$.XXXXXX)"
        line_numbers="$(grep -n '^###' "${includedir}/${testfile}" | cut -d ':' -f 1)"
        n="$(echo "${line_numbers}" | wc -l)"

        for ((i=1; i<=n-1; i++)); do
            start="$(sed -n "$i p" <<< "${line_numbers}")"
            end="$(sed -n "$((i+1)) p" <<< "${line_numbers}")"
            sed -n "${start},${end} p" "${includedir}/${testfile}" > "${filetmp}"
            source "${filetmp}"

            echo ''
            if [[ "${test}" != "${expected}" ]]; then
                ((n_fail+=1))

                # stdout
                echo -e "[  ${RED}FAILED${DEFAULT}  ] ${title}"
                printf "%12s ${YELLOW}%s${DEFAULT}\n" "" "Remediation: ${remediation}"

                # report
                printf "\n%s %s\n" "[  FAILED  ]" "${title}"                    >> "${audit_report}"
                printf "%s %s\n"   "            " "Remediation: ${remediation}" >> "${audit_report}"
            else
                ((n_pass+=1))

                # stdout
                echo -e "[    ${GREEN}OK${DEFAULT}    ] ${title}"

                # report
                printf "\n%s %s\n" "[    OK    ]" "${title}" >> "${audit_report}"
            fi
        done

        rm "${filetmp}"
    done
}

__print_summary() {
    echo
    printf "${DEFAULT}%s\n" "=================================================="
    printf "${DEFAULT}%s\n" "Audit complete."
    echo

    printf "${DEFAULT}%s\n" "SUMMARY"
    echo '-------'
    printf "${GREEN}%s${DEFAULT}\n" "PASS: ${n_pass}"
    printf "${RED}%s${DEFAULT}\n" "FAIL: ${n_fail}"
    echo

    printf "${DEFAULT}%s\n" "Audit file saved in current directory."
    echo "Filename: ${audit_report}"
    echo
}

__main() {
    __parse_options "$@"
    __check_euid
    __set_audit_report
    __set_colors
    __print_systeminfo
    __include_test_files
    __run_audit
    __print_summary
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
