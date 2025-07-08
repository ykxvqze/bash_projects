#!/usr/bin/env bash

<< 'EOF'
Utility functions for encrypting/decrypting via a one-time pad (OTP).

USAGE: ./otpcrypt.sh [ -h ]

OPTIONS:
      [ -h ]  Print usage

OUTPUT:
              Demo output in stdout (see: EXAMPLE).

DESCRIPTION:

- ascii_to_binary() takes a plaintext input (e.g. "I am Bob.") and
converts it into a continuous binary string not containing any space.

- binary_to_ascii() takes a binary string input and converts it to
plaintext by parsing and transforming every 8 bits into a character.

- generate_otp() takes a binary string input as returned by
ascii_to_binary() and generates a _random_ binary string of the same
length, L. It works by randomly shuffling the sequence of integers from
1 to L and then applying modulo 2 on each, effectively transforming even
numbers to 0 and odd numbers to 1.

- xor() requires two binary strings as input and applies a XOR operation
(bitwise), i.e., if bits are matching, the result is 0, otherwise 1.

- main() runs a demo of the encryption/decryption procedure.

EXAMPLE:

An example is demonstrated in main(). Running the script shows the
output. The plaintext sample used is: "I am Bob.". This is converted into
a binary string, an OTP of the same length is generated, the two binary
strings are then XORed, and the result is decrypted back into plaintext.

Sample output:

Plaintext (ASCII)        I am Bob.
Plaintext (binary)       010010010010000001100001011011010010000001000010011011110110001000101110
OTP/Key                  101100111101000110011101101110010100101101101011100011001000111100000000
Ciphertext (binary)      111110101111000111111100110101000110101100101001111000111110110100101110
Decrypted msg (binary)   010010010010000001100001011011010010000001000010011011110110001000101110
Decrypted msg (ASCII)    I am Bob.
EOF

set -Eeo pipefail

__print_usage     () { :; }
__ascii_to_binary () { :; }
__binary_to_ascii () { :; }
__xor             () { :; }
__generate_otp    () { :; }
__parse_options   () { :; }
__main            () { :; }

__print_usage() {
    echo -e "otpcrypt.sh: utility functions for one-time pad encryption/decryption.\n
    Usage:\n
    ./${0##*/}             Run demo
    ./${0##*/} [ -h ]      Print usage and exit\n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage; exit 0         ;;
            *) echo -e 'Incorrect usage!\n'; 
               __print_usage; exit 1         ;;
        esac
    done
}

__ascii_to_binary() {
    echo -n "$@"      |
    xxd -b            |
    cut -d ' ' -f 2-7 |
    tr '\n' ' '       |
    tr -d ' '
}

__binary_to_ascii() {
    string=$(echo "${1}" | sed 's/.\{8\}/&\ /g')
    for i in $string; do
        echo "obase=16; ibase=2; $i" |
        bc                           |
        tr '\n' ' '                  |
        xxd -r -p
    done;
}

__xor() {
    string1=$(echo "${1}" | tr -d ' ')
    string2=$(echo "${2}" | tr -d ' ')

    if [ "${#string1}" -ne "${#string2}" ]; then
        echo 'Strings are not of equal length!'
        return 1
    else
        for i in $(seq 1 ${#string1}); do
            [ "${string1:$((i-1)):1}" == "${string2:$((i-1)):1}" ] && echo -n '0' || echo -n '1'
        done
    fi
}

__generate_otp() {
    local string="${1}"
    local length="${#string}"
    for i in `shuf -i 1-"${length}"`; do
        echo -n $((i % 2))
    done
}

__set_colors() {
    GREEN='\e[32m'
    BLUE='\e[34m'
    DEFAULT='\e[0m'
}

__main() {
    __parse_options "$@"
    __set_colors

    plaintext_ascii='I am Bob.'
    plaintext_binary="$(__ascii_to_binary "${plaintext_ascii}")"
    key="$(__generate_otp "${plaintext_binary}")"
    ciphertext_binary="$(__xor "${plaintext_binary}" "${key}")"
    ciphertext_ascii="$(__binary_to_ascii "${ciphertext_binary}")"
    decrypted_binary="$(__xor "${ciphertext_binary}" "${key}")"
    decrypted_ascii="$(__binary_to_ascii "${decrypted_binary}")"

    {
    printf "${BLUE}Plaintext (ASCII)     : ${GREEN}%s${DEFAULT}\n" "${plaintext_ascii}  "
    printf "${BLUE}Plaintext (binary)    : ${GREEN}%s${DEFAULT}\n" "${plaintext_binary} "
    printf "${BLUE}OTP/Key               : ${GREEN}%s${DEFAULT}\n" "${key}              "
    printf "${BLUE}Ciphertext (binary)   : ${GREEN}%s${DEFAULT}\n" "${ciphertext_binary}"
    printf "${BLUE}Decrypted msg (binary): ${GREEN}%s${DEFAULT}\n" "${decrypted_binary} "
    printf "${BLUE}Decrypted msg (ASCII) : ${GREEN}%s${DEFAULT}\n" "${decrypted_ascii}  "
    } | column -t -s ':'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    __main "${@}"
fi
