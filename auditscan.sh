#!/usr/bin/env bash

setcolor() {
    rst='\e[0m'
    red='\e[31m'
    grn='\e[32m'
    blu='\e[34m'
}

filetmp='/tmp/config.json'
keys=`jq -r 'keys[]' audit.json`
setcolor

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
            printf "${red}%s${rst}\n" "[!] Audit step  : $audit"
            printf "${red}%s${rst}\n" "[-] Remediation : $remediation"
        else
            printf "${grn}%s${rst}\n" "[x] Audit step  : $audit"
        fi
     done
done
