#!/usr/bin/env bash
: '
Functions and a demo for encrypting/decrypting via a one-time pad (OTP).

USAGE: ./otp_crypt.sh [ -h ]

OPTIONS:
      [ -h ]  Print usage

OUTPUT:
              Demo output in stdout (see: EXAMPLE).

DESCRIPTION:

- Function ascii_to_binary() requires plaintext input (e.g. "I am Bob.")
and will convert the input into a binary string containing no spaces.
- Function binary_to_ascii() requires a binary string input (without spaces)
and converts it to plaintext (by parsing and transforming every 8 bits
into a character).
- Function generate_otp() requires a binary string input as returned by
ascii_to_binary() and generates a _random_ binary string of the same
length, L, by randomly shuffling the sequence of integers [1,...,L] and
then applying modulo 2 on each, effectively transforming even numbers to 0
and odd numbers to 1.
- Function xor() requires two binary string inputs and computes their XOR
(bitwise), i.e. if bits are matching, the result is 0, otherwise 1.
- Function main() runs a demo of the encryption/decryption procedure.

EXAMPLE:

An example is demonstrated in main(). Running the script will show the
output. The plaintext sample used is: "I am Bob.". This is converted into
a binary string, an OTP is generated of the same length, the two binary
strings are then XORed, and the result can be transformed into ciphertext (ASCII).

Sample output:

Plaintext (ASCII)        I am Bob.
Plaintext (binary)       010010010010000001100001011011010010000001000010011011110110001000101110
OTP/Key                  101100111101000110011101101110010100101101101011100011001000111100000000
Ciphertext (binary)      111110101111000111111100110101000110101100101001111000111110110100101110
Decrypted msg (binary)   010010010010000001100001011011010010000001000010011011110110001000101110
Decrypted msg (ASCII)    I am Bob.

J.A., xrzfyvqk_k1jw@pm.me
'

set -Eeo pipefail

print_usage() {
    echo -e "otp_crypt: demo and utility functions for one-time pad encryption/decryption.
    Usage:
    ./${0##*/}             Execute demo
    ./${0##*/} [ -h ]      Print usage and exit\n"
}

ascii_to_binary() {
    echo -n "$@"      |
    xxd -b            |
    cut -d ' ' -f 2-7 |
    tr '\n' ' '       |
    tr -d ' '
}

binary_to_ascii() {
    string=$(echo "$1" | sed 's/.\{8\}/&\ /g')
    for i in $string; do
        echo "obase=16; ibase=2; $i" |
        bc                           |
        tr '\n' ' '                  |
        xxd -r -p
    done;
}

xor() {
    string1=$(echo "$1" | tr -d ' ')
    string2=$(echo "$2" | tr -d ' ')

    if [ "${#string1}" -ne "${#string2}" ]; then
        echo 'Strings are not of equal length!'
        return 1
    else
        for i in `seq 1 ${#string1}`; do
            [ "${string1:$((i-1)):1}" == "${string2:$((i-1)):1}" ] && echo -n '0' || echo -n '1'
        done
    fi
}

generate_otp() {
    for i in `shuf -i 1-${#1}`; do
        echo -n $((i % 2))
    done
}

main() {
    # Parse
    while getopts 'h' option; do
        case $option in
            h) print_usage; exit 0         ;;
            *) echo -e 'Incorrect usage!\n'; 
               print_usage; exit 1         ;;
        esac
    done

    # Demo
    plaintext_ascii='I am Bob.'
    plaintext_binary=`ascii_to_binary "$plaintext_ascii"`
    key=`generate_otp "$plaintext_binary"`
    ciphertext_binary=`xor "$plaintext_binary" "$key"`
    ciphertext_ascii=`binary_to_ascii "$ciphertext_binary"`
    decrypted_binary=`xor "$ciphertext_binary" "$key"`
    decrypted_ascii=`binary_to_ascii "$decrypted_binary"`

    file_otp=`mktemp /tmp/file_otp.XXXXXX`

    grn='\e[32m'  # green
    blu='\e[34m'  # blue
    rst='\e[0m'   # reset

    printf "${blu}Plaintext (ASCII)     : ${grn}%s${rst}\n" "$plaintext_ascii  " >> "$file_otp"
    printf "${blu}Plaintext (binary)    : ${grn}%s${rst}\n" "$plaintext_binary " >> "$file_otp"
    printf "${blu}OTP/Key               : ${grn}%s${rst}\n" "$key              " >> "$file_otp"
    printf "${blu}Ciphertext (binary)   : ${grn}%s${rst}\n" "$ciphertext_binary" >> "$file_otp"
    printf "${blu}Decrypted msg (binary): ${grn}%s${rst}\n" "$decrypted_binary " >> "$file_otp"
    printf "${blu}Decrypted msg (ASCII) : ${grn}%s${rst}\n" "$decrypted_ascii  " >> "$file_otp"

    column -t -s ':' "$file_otp"
    rm "$file_otp"
}

main "$@"
