#!/usr/bin/env bash

setcolor() {
    rst='\e[0m'
    red='\e[31m'
    grn='\e[32m'
    blu='\e[34m'
}

audit_report="$PWD/audit_report_`date +'%Y_%m_%d_%H%M%S'`"

printf "%s%s\n" "Operating System         : `uname -s`"                         >> "${audit_report}"
printf "%s%s\n" "Operating System Name    : `lsb_release -i | sed 's/.*:\s//'`" >> "${audit_report}"
printf "%s%s\n" "Operating System Version : `lsb_release -d | sed 's/.*:\s//'`" >> "${audit_report}"
printf "%s%s\n" "Kernel Version           : `uname -r`"                         >> "${audit_report}"
printf "%s%s\n" "Hardware Platform        : `uname -m`"                         >> "${audit_report}"
printf "%s%s\n" "Hostname                 : `hostname`"                         >> "${audit_report}"

filetmp='/tmp/config.json'
keys=`jq -r 'keys[]' audit.json`
setcolor

n_pass=0
n_fail=0

for key in $keys; do
    sed -n "/\"${key////\\/}\"/,/\s]/p" audit.json |
    sed '1d' | sed '$d' | sed -E '1 s/(.*)/[\n&/'       |
    sed -E '$ s/}/&\n]/' > $filetmp

    titles=`jq -r '.[].title' "$filetmp"`
    audits=`jq -r '.[].audit' "$filetmp"`
    expected_values=`jq -r '.[].expected' "$filetmp"`
    remediations=`jq -r '.[].remediation' "$filetmp"`

    n=`echo "$titles" | wc -l`

    echo ''
    printf "${blu}%s${rst}\n" "-------------------- [ $key ] --------------------"

    for i in `seq 1 "$n"`; do
        title=`echo "$titles" | sed -n "$i p"`
        audit=`echo "$audits" | sed -n "$i p"`
        expected=`echo "$expected_values" | sed -n "$i p"`
        remediation=`echo "$remediations" | sed -n "$i p"`

        echo ''
        printf '%s\n' "[*] $title"
        eval "$audit" &> /dev/null
        if [ "`eval "$audit" 2>/dev/null`" != "$expected" ]; then
            ((n_fail+=1))

            # stdout
            printf "${red}%s${rst}\n" "[X] Audit step  : $audit"
            printf "${red}%s${rst}\n" "[-] Remediation : $remediation"

            # report
            printf "\n%s%s\n" "/!\ [FAIL]" "[*] $title"                     >> "${audit_report}"
            printf "%s%s\n  " "          " "[X] Audit step  : $audit"       >> "${audit_report}"
            printf "%s%s\n  " "          " "[-] Remediation : $remediation" >> "${audit_report}"
        else
            ((n_pass+=1))

            # stdout
            printf "${grn}%s${rst}\n" "[V] Audit step  : $audit"

            # report
            printf "\n%s%s\n" "    [PASS]" "[*] $title"                   >> "${audit_report}"
            printf "%s%s\n  " "          " "[V] Audit step  : $audit"     >> "${audit_report}"
        fi
     done
done

echo
printf "${rst}%s\n" "=================================================="
printf "${rst}%s${rst}\n" "Audit complete."
echo

printf "${rst}%s${rst}\n" "SUMMARY"
echo '-------'
printf "${grn}%s${grn}\n" "PASS: ${n_pass}"
printf "${red}%s${red}\n" "FAIL: ${n_fail}"
echo

printf "${rst}%s${rst}\n" "Audit file saved in current directory."
echo "Filename: ${audit_report}"
echo
