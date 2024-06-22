#!/usr/bin/env bash
: '
A script for server security auditing.

USAGE: ./scansec.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
         "OK" or "WARNING"/remediation results in stdout, in addition to
         an audit report saved in the current work directory. The report
         includes OS/kernel information and the audit results.

DESCRIPTION:

scansec.sh will check for several configuration settings relating to
system files and network. The main audit rules are separated into files
and listed under the directory ./tests. More rules can be easily added
to the files which are made separate from the display. The script will
audit each entry appearing in the files by testing against an expected
output listed there. If there is a match with the expected output, the
test is marked as OK, otherwise it is marked with a WARNING (and a
remediation step is listed in such a case). In this design, the test
files can be expanded independently to include more rules as these are
not hard-coded into the main script itself, which only handles the
display.
'

print_usage(){
    echo
    echo -e "scansec.sh: security auditing
    Usage: sudo ./${0##*/}
                ./${0##*/} -h     Print usage and exit\n"
}

if [ "$1" == '-h' ]; then
    print_usage
    exit 0
fi

if [ $EUID -ne 0 ]; then
    echo -e '\nPlease run this script as a privileged user, e.g.'
    echo
    echo -e 'sudo ./scansec.sh\n'
    exit 1
fi

setcolor() {
    DEFAULT='\e[0m'
    RED='\e[31m'
    GREEN='\e[32m'
    YELLOW='\e[33m'
    BLUEE='\e[34m'
}
setcolor

audit_report="$PWD/audit_report_`date +'%Y_%m_%d_%H%M%S'`"

echo ''
echo -e "[+] ${YELLOW}Operating System Information${DEFAULT}"
echo "----------------------------------------"
printf "%s\n" "Operating System         : `uname -s`"                         | tee -a "${audit_report}"
printf "%s\n" "Operating System Name    : `lsb_release -i | sed 's/.*:\s//'`" | tee -a "${audit_report}"
printf "%s\n" "Operating System Version : `lsb_release -d | sed 's/.*:\s//'`" | tee -a "${audit_report}"
printf "%s\n" "Kernel Version           : `uname -r`"                         | tee -a "${audit_report}"
printf "%s\n" "Hardware Platform        : `uname -m`"                         | tee -a "${audit_report}"
printf "%s\n" "Hostname                 : `hostname`"                         | tee -a "${audit_report}"

# test files
includedir='./tests'
testfiles=$(ls "$includedir")

n_pass=0
n_fail=0

for testfile in $testfiles; do
    echo ''
    echo -e "[+] ${YELLOW}$(sed -n '1 p' ${includedir}/${testfile})${DEFAULT}"
    echo "----------------------------------------"

    filetmp="$(mktemp /tmp/file.XXXXXX)"
    line_numbers="$(grep -n '^###' "${includedir}/${testfile}" | cut -d ':' -f 1)"
    n="$(echo "$line_numbers" | wc -l)"

    trap 'rm "$filetmp"' INT TERM EXIT

    for i in $(seq 1 $((n-1)) ); do
        start="$(sed -n "$i p" <<< "$line_numbers")"
        end="$(sed -n "$((i+1)) p" <<< "$line_numbers")"
        sed -n "${start},${end} p" "${includedir}/${testfile}" > "${filetmp}"
        source "${filetmp}"

        echo ''
        if [ "$test" != "$expected" ]; then
            ((n_fail+=1))

            # stdout
            echo -e "[ ${RED}WARNING!${DEFAULT} ] $title"
            printf "%11s ${YELLOW}%s${DEFAULT}\n" "" ">> Remediation: ${remediation}"

            # report
            printf "\n%s %s\n" "[ WARNING! ]" "$title" >> "${audit_report}"
            printf "%s %s\n"   "            " ">> Remediation : $remediation" >> "${audit_report}"
        else
            ((n_pass+=1))

            # stdout
            echo -e "[ ${GREEN}   OK   ${DEFAULT} ] $title"
        
            # report
            printf "\n%s %s\n" "[    OK    ]" "$title" >> "${audit_report}"
        fi
     done
done

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
