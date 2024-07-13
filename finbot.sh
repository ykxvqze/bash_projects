#!/usr/bin/env bash

<< EOF

10[0];20[1-5];{100,G=25,6-10};{1000,g=2%,11-15}@[5-10],i=6%

PW = 10(P/F,6%,0) + 20(P/A,6%,5) + 100(P/A,6%,5)(P/F,6%,5) + 25(P/G,6%,5)(P/F,6%,5) + p_g(1000,2%,6%,5)(P/F,6%,10)
A = PW(F/P,6%,4)(A/P,6%,6)

required:

P/F
P/A
P/G
P/g
A/P
F/P

EOF

pf() {
    i=$1
    n=$2
    echo "1 / (1 + ($i / 100))^$n" | bc -l
}

<< EOF
factor=$(pf 6 1)
echo "10 * $factor" | bc -l
EOF

fp() {
    i=$1
    n=$2
    echo "(1 + ($i / 100))^$n" | bc -l
}

<< EOF
factor=$(fp 6 1)
echo "10 * $factor" | bc -l
EOF

pa() {
    i=$1
    n=$2
    echo "((1 + ($i / 100))^$n - 1) / ($i / 100 * (1 + ($i / 100))^$n )" | bc -l
}

<< EOF
factor=$(pa 6 10)
echo "100 * $factor" | bc -l
EOF

ap() {
   i=$1
   n=$2
   echo "1 / $(pa $i $n)" | bc -l
}

<< EOF
factor=$(ap 6 5)
echo "100 * $factor" | bc -l
EOF

pg() {
    i=$1
    n=$2
    echo "((1 + ($i / 100))^$n - ($n * $i / 100) - 1) / (($i / 100)^2 * (1 + ($i /100))^$n )"
}

<< EOF
factor=$(pg 6 10)
echo "100 * $factor" | bc -l
EOF

p_g() {
    g=$1
    i=$2
    n=$3
    if [ $i -ne $g ]; then
        echo "(1 - ( (1+($g / 100))^$n / (1 + ($i / 100))^$n )) / (($i / 100) - ($g / 100) )" | bc -l
    else
        echo "$n / (1 + ($i / 100))" | bc -l
    fi
}

<< EOF
factor=$(p_g 2 6 10)
echo "100 * $factor" | bc -l
EOF

is_real() {
    arg=$1
    [[ "$arg" =~ ^-?([0-9]+)?(\.)?[0-9]+$ ]]
}

is_non_negative_integer() {
    arg=$1
    [[ "$arg" =~ ^[0-9]+$ ]]
}

check_cf_single() {
    local input="$@"
    [[ "$input" =~ ^([^[]+)\[([^]]+)\]$ ]] || { echo "incorrect single CF form: $input"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    is_real "$arg1" || { echo "single CF quantity is not real: $arg1"; return 1; }
    is_non_negative_integer "$arg2" || { echo "single CF time must be a non-negative integer: $arg2"; return 1; }
}

<< EOF
check_cf_single 5
check_cf_single '-0.5[10]'
check_cf_single '-50[10]'
check_cf_single '3.42[10]'
check_cf_single '10.4[5.1]'
EOF

check_cf_uniform() {
    local input="$@"
    [[ "$input" =~ ^([^[]+)\[([^]-]+)\-([^[-]+)\]$ ]] || { echo "incorrect uniform CF form: $input"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"
    is_real "$arg1" || { echo "uniform CF quantity is not real: $arg1"; return 1; }
    is_non_negative_integer "$arg2" || { echo "uniform CF start time must be a non-negative integer: $arg2"; return 1; }
    is_non_negative_integer "$arg3" || { echo "uniform CF end time must be a non-negative integer: $arg3"; return 1; }
    [ "$arg2" -lt "$arg3" ] || { echo "uniform CF start time $arg2 should precede end time $arg3"; return 1; }
}

<< EOF
check_cf_uniform -5[1-10]
check_cf_uniform 1.2[0-5]
check_cf_uniform 3.2[0-5.2]
check_cf_uniform 5[5-2]
EOF

check_gradient_arithmetic() {
    local input="$@"
    [[ "$input" =~ ^\{([^,]+),G=([^,]+),([^,]+)\}$ ]] || { echo "incorrect arithmetic gradient form: $input"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"
    is_real "$arg1" || { echo "arithmetic gradient initial CF is not real: $arg1"; return 1; }
    is_real "$arg2" || { echo "arithmetic gradient G is not real: $arg2"; return 1; }
    [[ "$arg3" =~ ^([^]-]+)\-([^[-]+)$ ]] || { echo "arithmetic gradient duration form is incorrect: $arg2"; return 1; }
    local arg3a=${BASH_REMATCH[1]}
    local arg3b=${BASH_REMATCH[2]}
    is_non_negative_integer "$arg3a" || { echo "arithmetic gradient start time must be a non-negative integer: $arg3a"; return 1; }
    is_non_negative_integer "$arg3b" || { echo "arithmetic gradient end time must be a non-negative integer: $arg3b"; return 1; }
    [ "$arg3a" -lt "$arg3b" ] || { echo "arithmetic gradient start time $arg3a should precede end time $arg3b"; return 1; }
}

<< EOF
check_gradient_arithmetic '{100.1,G=25.3,2-8}'
check_gradient_arithmetic '{-100.1,G=-25.3,[2-8]}'
check_gradient_arithmetic '{100.1,G=25.3,8-2}'
EOF

check_gradient_geometric() {
    local input="$@"
    [[ "$input" =~ ^\{([^,]+),g=([^,]+)%,([^,]+)\}$ ]] || { echo "incorrect geometric gradient form: $input"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"
    is_real "$arg1" || { echo "geometric gradient initial CF is not real: $arg1"; return 1; }
    is_real "$arg2" || { echo "geometric gradient g is not real: '$arg2'"; return 1; }
    [[ "$arg3" =~ ^([^]-]+)\-([^[-]+)$ ]] || { echo "geometric gradient duration form is incorrect: $arg2"; return 1; }
    local arg3a=${BASH_REMATCH[1]}
    local arg3b=${BASH_REMATCH[2]}
    is_non_negative_integer "$arg3a" || { echo "geometric gradient start time must be a non-negative integer: $arg3a"; return 1; }
    is_non_negative_integer "$arg3b" || { echo "geometric gradient end time must be a non-negative integer: $arg3b"; return 1; }
    [ "$arg3a" -lt "$arg3b" ] || { echo "geometric gradient start time $arg3a should precede end time $arg3b"; return 1; }
}

<< EOF
check_gradient_geometric '{100.1,g=25.3%,2-8}'
check_gradient_geometric '{-100.1,g=-25.3%,[2-8]}'
check_gradient_geometric '{100.1,g=3%%,8-2}'
EOF

validate_input() {
    local input="$@"
    [[ "$input" =~ ^([^@]+)@([^,]+),i=([^,]+)%$ ]] || { echo "incorrect input form: $input"; return 1; }
    local arg1="${BASH_REMATCH[1]}"
    local arg2="${BASH_REMATCH[2]}"
    local arg3="${BASH_REMATCH[3]}"

    is_real "$arg3" || { echo "i is not real: $arg3"; return 1; }

    local target_single_value=''
    [[ "$arg2" =~ ^[0-9]+$ ]] && target_single_value=true
    if [ "$target_single_value" != 'true' ]; then
        [[ "$arg2" =~ ^\[([^]-]+)\-([^[-]+)\]$ ]] || { echo "target time or duration has an incorrect form: $arg2"; return 1; }
        local arg2a="${BASH_REMATCH[1]}"
        local arg2b="${BASH_REMATCH[2]}"
        is_non_negative_integer "$arg2a" || { echo "target start time must be a non-negative integer: $arg2a"; return 1; }
        is_non_negative_integer "$arg2b" || { echo "target end time must be a non-negative integer: $arg2b"; return 1; }
        [ "$arg2a" -lt "$arg2b" ] || { echo "target start time $arg2a should precede end time $arg2b"; return 1; }
    fi

    factors=$(echo "$arg1" | tr ';' ' ')
    for i in $factors; do
        check_cf_single "$i"           &> /dev/null || \
        check_cf_uniform "$i"          &> /dev/null || \
        check_gradient_arithmetic "$i" &> /dev/null || \
        check_gradient_geometric "$i"  &> /dev/null || \
        { echo "incorrect factor form: $i"; return 1; }
    done
}

<< EOF
validate_input '10[0];{100,G=-5.3,1-3}@[5-10],i=4%'
validate_input '10[0];{100,G=-5.3%,1-3}@[5-10],i=4%'
validate_input '10[0];{100,g=-5.3%,1-3}@[5-10],i=4%'
validate_input '10[0];{100,G=-5.3,1-3}@[10-1],i=4%'
EOF

compute() {
    input="$@"
    validate_input "$input" || return 1

    [[ "$input" =~ ^([^@]+)@([^,]+),i=([^,]+)%$ ]]
    arg1="${BASH_REMATCH[1]}"
    arg2="${BASH_REMATCH[2]}"
    arg3="${BASH_REMATCH[3]}"

    i="$arg3"
    target_single_value=''
    [[ "$arg2" =~ ^[0-9]+$ ]] && target_single_value=true

    PW=0
    factors=$(echo "$arg1" | tr ';' ' ')
    for factor in $factors; do
        if check_cf_single "$factor" &> /dev/null ; then
            [[ "$factor" =~ ^([^[]+)\[([^]]+)\]$ ]]
            q="${BASH_REMATCH[1]}"
            n="${BASH_REMATCH[2]}"
            P=$(echo "$q * $(pf $i $n)" | bc -l)
            PW=$(echo "$PW + $P" | bc -l)
        elif check_cf_uniform "$factor" &> /dev/null ; then
            [[ "$factor" =~ ^([^[]+)\[([^]-]+)\-([^[-]+)\]$ ]]
            q="${BASH_REMATCH[1]}"
            t_s="${BASH_REMATCH[2]}"
            t_f="${BASH_REMATCH[3]}"
            n=$((t_f - t_s + 1))
            t_i=$((t_s - 1))
            P=$(echo "$q * $(pa $i $n) * $(pf $i $t_i)" | bc -l)
            PW=$(echo "$PW + $P" | bc -l)
        elif check_gradient_arithmetic "$factor" &> /dev/null ; then
            [[ "$factor" =~ ^\{([^,]+),G=([^,]+),([^,]+)\}$ ]]
            q="${BASH_REMATCH[1]}"
            G="${BASH_REMATCH[2]}"
            duration="${BASH_REMATCH[3]}"
            [[ "$duration" =~ ^([^]-]+)\-([^[-]+)$ ]]
            t_s=${BASH_REMATCH[1]}
            t_f=${BASH_REMATCH[2]}
            n=$((t_f - t_s + 1))
            t_i=$((t_s - 1))
            P_A=$(echo "$q * $(pa $i $n) * $(pf $i $t_i)" | bc -l)
            P_G=$(echo "$G * $(pg $i $n) * $(pf $i $t_i)" | bc -l)
            PW=$(echo "$PW + $P_A + $P_G" | bc -l)
        elif check_gradient_geometric "$factor" &> /dev/null ; then
            [[ "$factor" =~ ^\{([^,]+),g=([^,]+)%,([^,]+)\}$ ]]
            q="${BASH_REMATCH[1]}"
            g="${BASH_REMATCH[2]}"
            duration="${BASH_REMATCH[3]}"
            [[ "$duration" =~ ^([^]-]+)\-([^[-]+)$ ]]
            t_s=${BASH_REMATCH[1]}
            t_f=${BASH_REMATCH[2]}
            n=$((t_f - t_s + 1))
            t_i=$((t_s - 1))
            P=$(echo "$q * $(p_g $g $i $n) * $(pf $i $t_i)" | bc -l)
            PW=$(echo "$PW + $P" | bc -l)
        else
            echo "factor has an unknown form: $factor"
        fi
    done

    if [ "$target_single_value" == 'true' ]; then
        t="$arg2"
        result=$(echo "$PW * $(fp $i $t)" | bc -l)
    else
        [[ "$arg2" =~ ^\[([^]-]+)\-([^[-]+)\]$ ]]
        t_s="${BASH_REMATCH[1]}"
        t_f="${BASH_REMATCH[2]}"
        n=$((t_f - t_s + 1))
        result=$(echo "$PW * $(fp $i $((t_s - 1)) ) * $(ap $i $n)" | bc -l )
    fi

    echo "$result"
}

<< EOF
compute '10[0];5[1-5]@5,i=4%'
compute '{0,G=25,3-5}@5,i=4%'
compute '100[1-4];{0,G=-25,1-4}@0,i=10%'
compute '{100,G=-25,1-4}@0,i=10%'
compute '-8000[0];{-1700,g=11%,1-6};200[6]@0,i=8%'
compute '8000[3-8]@8,i=16%'
compute '8000[3-8]@[1-8],i=16%'
compute '5000000[0];2000000[10];100000[11-10000]@[1-10000],i=10%'
compute '1000[0];1000[3];1000[6];1000[9];1000[12];1000[15]@[1-18],i=10%'
compute '-15000[0];-3500[1-6];1000[6]@[1-6],i=15%'
EOF
