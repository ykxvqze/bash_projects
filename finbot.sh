#!/usr/bin/env bash

<< EOF
CF computations

USAGE:

      ./finbot.sh '10[0];20[1-5];{100,G=25,6-10};{1000,g=2%,11-15}@[5-10],i=6%'

DESCRIPTION:

PW = 10(P/F,6%,0) + 20(P/A,6%,5) + 100(P/A,6%,5)(P/F,6%,5) + 25(P/G,6%,5)(P/F,6%,5) + p_g(1000,2%,6%,5)(P/F,6%,10)
A = PW(F/P,6%,4)(A/P,6%,6)

Required factors for any computation:

P/F
P/A
P/G
P/g
A/P
F/P

EOF

__pf                          () { :; }
__fp                          () { :; }
__pa                          () { :; }
__ap                          () { :; }
__pg                          () { :; }
__p_g                         () { :; }
__is_real                     () { :; }
__is_non_negative_integer     () { :; }
__is_cf_single                () { :; }
__is_cf_uniform               () { :; }
__is_arithmetic_gradient      () { :; }
__is_geometric_gradient       () { :; }
__validate_input              () { :; }
__compute_cf_single           () { :; }
__compute_cf_uniform          () { :; }
__compute_arithmetic_gradient () { :; }
__compute_geometric_gradient  () { :; }
__compute                     () { :; }
__print_usage                 () { :; }
__check_nargs                 () { :; }
__parse_arguments             () { :; }
__main                        () { :; }

__pf() {
    local i="${1}"
    local n="${2}"
    echo "1 / (1 + (${i} / 100))^${n}" | bc -l
}

<< EOF
factor=$(__pf 6 1)
echo "10 * ${factor}" | bc -l
EOF

__fp() {
    local i="${1}"
    local n="${2}"
    echo "(1 + (${i} / 100))^${n}" | bc -l
}

<< EOF
factor=$(__fp 6 1)
echo "10 * ${factor}" | bc -l
EOF

__pa() {
    local i="${1}"
    local n="${2}"
    echo "((1 + (${i} / 100))^${n} - 1) / (${i} / 100 * (1 + (${i} / 100))^${n} )" | bc -l
}

<< EOF
factor=$(__pa 6 10)
echo "100 * ${factor}" | bc -l
EOF

__ap() {
   local i="${1}"
   local n="${2}"
   echo "1 / $(__pa ${i} ${n})" | bc -l
}

<< EOF
factor=$(__ap 6 5)
echo "100 * ${factor}" | bc -l
EOF

__pg() {
    local i="${1}"
    local n="${2}"
    echo "((1 + (${i} / 100))^${n} - (${n} * ${i} / 100) - 1) / ((${i} / 100)^2 * (1 + (${i} /100))^${n} )"
}

<< EOF
factor=$(__pg 6 10)
echo "100 * ${factor}" | bc -l
EOF

__p_g() {
    local g="${1}"
    local i="${2}"
    local n="${3}"
    if [ "${i}" -ne "${g}" ]; then
        echo "(1 - ( (1+(${g} / 100))^${n} / (1 + (${i} / 100))^${n} )) / ((${i} / 100) - (${g} / 100) )" | bc -l
    else
        echo "${n} / (1 + (${i} / 100))" | bc -l
    fi
}

<< EOF
factor=$(__p_g 2 6 10)
echo "100 * ${factor}" | bc -l
EOF

__is_real() {
    local arg="${1}"
    [[ "${arg}" =~ ^-?([0-9]+)?(\.)?[0-9]+$ ]]
}

__is_non_negative_integer() {
    local arg="${1}"
    [[ "${arg}" =~ ^[0-9]+$ ]]
}

__is_cf_single() {
    local input="${@}"
    [[ "${input}" =~ ^([^[]+)\[([^]]+)\]$ ]] || { echo "incorrect single CF form: ${input}"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    __is_real "${arg1}"                 || { echo "single CF quantity is not real: ${arg}1"               ; return 1; }
    __is_non_negative_integer "${arg2}" || { echo "single CF time must be a non-negative integer: ${arg2}"; return 1; }
}

<< EOF
__is_cf_single 5
__is_cf_single '-0.5[10]'
__is_cf_single '-50[10]'
__is_cf_single '3.42[10]'
__is_cf_single '10.4[5.1]'
EOF

__is_cf_uniform() {
    local input="${@}"
    [[ "${input}" =~ ^([^[]+)\[([^]-]+)\-([^[-]+)\]$ ]] || { echo "incorrect uniform CF form: ${input}"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"
    __is_real "${arg1}"                 || { echo "uniform CF quantity is not real: ${arg1}"                     ; return 1; }
    __is_non_negative_integer "${arg2}" || { echo "uniform CF start time must be a non-negative integer: ${arg2}"; return 1; }
    __is_non_negative_integer "${arg3}" || { echo "uniform CF end time must be a non-negative integer: ${arg3}"  ; return 1; }
    [ "${arg2}" -lt "${arg3}" ]              || { echo "uniform CF start time $arg2 should precede end time ${arg3}"  ; return 1; }
}

<< EOF
__is_cf_uniform -5[1-10]
__is_cf_uniform 1.2[0-5]
__is_cf_uniform 3.2[0-5.2]
__is_cf_uniform 5[5-2]
EOF

__is_arithmetic_gradient() {
    local input="${@}"
    [[ "${input}" =~ ^\{([^,]+),G=([^,]+),([^,]+)\}$ ]] || { echo "incorrect arithmetic gradient form: ${input}"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"
    __is_real "${arg1}"                || { echo "arithmetic gradient initial CF is not real: ${arg1}"    ; return 1; }
    __is_real "${arg2}"                || { echo "arithmetic gradient G is not real: ${arg2}"             ; return 1; }
    [[ "${arg3}" =~ ^([^]-]+)\-([^[-]+)$ ]] || { echo "arithmetic gradient duration form is incorrect: ${arg2}"; return 1; }
    local arg3a="${BASH_REMATCH[1]}"
    local arg3b="${BASH_REMATCH[2]}"
    __is_non_negative_integer "${arg3a}" || { echo "arithmetic gradient start time must be a non-negative integer: ${arg3a}"; return 1; }
    __is_non_negative_integer "${arg3b}" || { echo "arithmetic gradient end time must be a non-negative integer: ${arg3b}"  ; return 1; }
    [ "${arg3a}" -lt "${arg3b}" ]             || { echo "arithmetic gradient start time $arg3a should precede end time ${arg3b}" ; return 1; }
}

<< EOF
__is_arithmetic_gradient '{100.1,G=25.3,2-8}'
__is_arithmetic_gradient '{-100.1,G=-25.3,[2-8]}'
__is_arithmetic_gradient '{100.1,G=25.3,8-2}'
EOF

__is_geometric_gradient() {
    local input="${@}"
    [[ "${input}" =~ ^\{([^,]+),g=([^,]+)%,([^,]+)\}$ ]] || { echo "incorrect geometric gradient form: ${input}"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"
    __is_real "${arg1}"                || { echo "geometric gradient initial CF is not real: ${arg1}"    ; return 1; }
    __is_real "${arg2}"                || { echo "geometric gradient g is not real: '${arg2}'"           ; return 1; }
    [[ "${arg3}" =~ ^([^]-]+)\-([^[-]+)$ ]] || { echo "geometric gradient duration form is incorrect: ${arg2}"; return 1; }
    local arg3a="${BASH_REMATCH[1]}"
    local arg3b="${BASH_REMATCH[2]}"
    __is_non_negative_integer "${arg3a}" || { echo "geometric gradient start time must be a non-negative integer: ${arg3a}" ; return 1; }
    __is_non_negative_integer "${arg3b}" || { echo "geometric gradient end time must be a non-negative integer: ${arg3b}"   ; return 1; }
    [ "${arg3a}" -lt "${arg3b}" ]             || { echo "geometric gradient start time ${arg3a} should precede end time ${arg3b}"; return 1; }
}

<< EOF
__is_geometric_gradient '{100.1,g=25.3%,2-8}'
__is_geometric_gradient '{-100.1,g=-25.3%,[2-8]}'
__is_geometric_gradient '{100.1,g=3%%,8-2}'
EOF

__validate_input() {
    local input="${@}"
    [[ "${input}" =~ ^([^@]+)@([^,]+),i=([^,]+)%$ ]] || { echo "incorrect input form: ${input}"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"

    __is_real "${arg3}" || { echo "i is not real: ${arg3}"; return 1; }

    local target_single_value=''
    [[ "${arg2}" =~ ^[0-9]+$ ]] && target_single_value=true
    if [ "${target_single_value}" != 'true' ]; then
        [[ "${arg2}" =~ ^\[([^]-]+)\-([^[-]+)\]$ ]] || { echo "target time or duration has an incorrect form: ${arg2}"     ; return 1; }
        local arg2a="${BASH_REMATCH[1]}"
        local arg2b="${BASH_REMATCH[2]}"
        __is_non_negative_integer "${arg2a}"   || { echo "target start time must be a non-negative integer: ${arg2a}" ; return 1; }
        __is_non_negative_integer "${arg2b}"   || { echo "target end time must be a non-negative integer: ${arg2b}"   ; return 1; }
        [ "${arg2a}" -lt "${arg2b}" ]               || { echo "target start time ${arg2a} should precede end time ${arg2b}"; return 1; }
    fi

    local factors=$(echo "${arg1}" | tr ';' ' ')
    for i in $factors; do
        __is_cf_single "${i}"           &> /dev/null || \
        __is_cf_uniform "${i}"          &> /dev/null || \
        __is_arithmetic_gradient "${i}" &> /dev/null || \
        __is_geometric_gradient "${i}"  &> /dev/null || \
        { echo "incorrect factor form: ${i}"; return 1; }
    done
}

<< EOF
__validate_input '10[0];{100,G=-5.3,1-3}@[5-10],i=4%'
__validate_input '10[0];{100,G=-5.3%,1-3}@[5-10],i=4%'
__validate_input '10[0];{100,g=-5.3%,1-3}@[5-10],i=4%'
__validate_input '10[0];{100,G=-5.3,1-3}@[10-1],i=4%'
EOF

__compute_cf_single() {
    local input="${@}"
    [[ "${input}" =~ ^([^[]+)\[([^]]+)\]$ ]]
    local q="${BASH_REMATCH[1]}"
    local n="${BASH_REMATCH[2]}"
    local P=$(echo "${q} * $(__pf ${i} ${n})" | bc -l)
    echo "${P}"
}

__compute_cf_uniform() {
    local input="${@}"
    [[ "${input}" =~ ^([^[]+)\[([^]-]+)\-([^[-]+)\]$ ]]
    local q="${BASH_REMATCH[1]}"
    local t_s="${BASH_REMATCH[2]}"
    local t_f="${BASH_REMATCH[3]}"
    local n=$((t_f - t_s + 1))
    local t_i=$((t_s - 1))
    local P=$(echo "${q} * $(__pa ${i} ${n}) * $(__pf ${i} ${t_i})" | bc -l)
    echo "${P}"
}

__compute_arithmetic_gradient() {
    local input="${@}"
    [[ "${input}" =~ ^\{([^,]+),G=([^,]+),([^,]+)\}$ ]]
    local q="${BASH_REMATCH[1]}"
    local G="${BASH_REMATCH[2]}"
    local duration="${BASH_REMATCH[3]}"
    [[ "${duration}" =~ ^([^]-]+)\-([^[-]+)$ ]]
    local t_s="${BASH_REMATCH[1]}"
    local t_f="${BASH_REMATCH[2]}"
    local n=$((t_f - t_s + 1))
    local t_i=$((t_s - 1))
    local P_A=$(echo "${q} * $(__pa ${i} ${n}) * $(__pf ${i} ${t_i})" | bc -l)
    local P_G=$(echo "${G} * $(__pg ${i} ${n}) * $(__pf ${i} ${t_i})" | bc -l)
    local P=$(echo "${P_A} + ${P_G}" | bc -l)
    echo "${P}"
}

__compute_geometric_gradient() {
    local input="${@}"
    [[ "${input}" =~ ^\{([^,]+),g=([^,]+)%,([^,]+)\}$ ]]
    local q="${BASH_REMATCH[1]}"
    local g="${BASH_REMATCH[2]}"
    local duration="${BASH_REMATCH[3]}"
    [[ "${duration}" =~ ^([^]-]+)\-([^[-]+)$ ]]
    local t_s="${BASH_REMATCH[1]}"
    local t_f="${BASH_REMATCH[2]}"
    local n=$((t_f - t_s + 1))
    local t_i=$((t_s - 1))
    local P=$(echo "${q} * $(__p_g ${g} ${i} ${n}) * $(__pf ${i} ${t_i})" | bc -l)
    echo "${P}"
}

__compute() {
    input="${@}"
    __validate_input "${input}" || return 1

    [[ "${input}" =~ ^([^@]+)@([^,]+),i=([^,]+)%$ ]]
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"

    local i="${arg3}"
    local target_single_value=''
    [[ "${arg2}" =~ ^[0-9]+$ ]] && target_single_value=true

    local PW=0
    local factors=$(echo "${arg1}" | tr ';' ' ')
    for factor in $factors; do
        if __is_cf_single "${factor}" &> /dev/null ; then
            P=$(__compute_cf_single "${factor}")
            PW=$(echo "${PW} + ${P}" | bc -l)
        elif __is_cf_uniform "${factor}" &> /dev/null ; then
            P=$(__compute_cf_uniform "${factor}")
            PW=$(echo "${PW} + ${P}" | bc -l)
        elif __is_arithmetic_gradient "${factor}" &> /dev/null ; then
            P=$(__compute_arithmetic_gradient "${factor}")
            PW=$(echo "${PW} + ${P}" | bc -l)
        elif __is_geometric_gradient "${factor}" &> /dev/null ; then
            P=$(__compute_geometric_gradient "${factor}")
            PW=$(echo "${PW} + ${P}" | bc -l)
        else
            echo "factor has an unknown form: ${factor}"
        fi
    done

    if [ "${target_single_value}" == 'true' ]; then
        t="${arg2}"
        result=$(echo "${PW} * $(__fp ${i} ${t})" | bc -l)
    else
        [[ "${arg2}" =~ ^\[([^]-]+)\-([^[-]+)\]$ ]]
        t_s="${BASH_REMATCH[1]}"
        t_f="${BASH_REMATCH[2]}"
        n=$((t_f - t_s + 1))
        result=$(echo "${PW} * $(__fp ${i} $((t_s - 1)) ) * $(__ap ${i} ${n})" | bc -l )
    fi

    echo "${result}"
}

<< EOF
__compute '10[0];5[1-5]@5,i=4%'
__compute '{0,G=25,3-5}@5,i=4%'
__compute '100[1-4];{0,G=-25,1-4}@0,i=10%'
__compute '{100,G=-25,1-4}@0,i=10%'
__compute '-8000[0];{-1700,g=11%,1-6};200[6]@0,i=8%'
__compute '8000[3-8]@8,i=16%'
__compute '8000[3-8]@[1-8],i=16%'
__compute '5000000[0];2000000[10];100000[11-10000]@[1-10000],i=10%'
__compute '1000[0];1000[3];1000[6];1000[9];1000[12];1000[15]@[1-18],i=10%'
__compute '-15000[0];-3500[1-6];1000[6]@[1-6],i=15%'
EOF

__print_usage() {
    echo -e "
            USAGE:

            ./${0##*/} '10[0];5[1-5]@5,i=4%'
            ./${0##*/} '-15000[0];-3500[1-6];1000[6]@[1-6],i=15%' \n"
}

__check_nargs() {
    if [ "$#" -ne 1 ]; then
        echo 'The number of arguments should be 1.'
        __print_usage
        exit 1
    fi
}

__parse_arguments() {
    if [ "$1" == "-h" ]; then
        __print_usage
        exit 0
    else
        input="${1}"
    fi
}

__main() {
    __check_nargs "$@"
    __parse_arguments "$@"
    __compute "${input}"
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    __main "$@"
fi
