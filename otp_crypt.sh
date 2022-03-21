#!/usr/bin/env bash
: ' 
Functions and a demo for encrypting/decrypting via a one-time pad (OTP).

USAGE: ./otp_crypt.sh [ -h ]

OPTIONS:
      [ -h ]  Print usage

OUTPUT:
              Demo output in stdout (see: EXAMPLE).

DESCRIPTION:

* Function ascii_to_binary() requires a plaintext input (e.g. "I am Bob.")
and will convert the input into a binary string containing no spaces.
* Function binary_to_ascii() requires a binary string input (without spaces)
and converts it to plaintext (by parsing and transforming every 8 bits
into a character).
* Function generate_otp() requires a binary string input as returned by
ascii_to_binary() and generates a _random_ binary string of the same
length, L, by randomly shuffling the sequence of integers [1,...,L] and
then applying modulo 2 on each, effectively transforming even numbers to 0
and odd numbers to 1.
* Function xor() requires two binary string inputs and computes their XOR
(bitwise), i.e. if bits are matching, the result is 0, otherwise 1.
* Function main() runs a demo of the encryption/decryption procedure.

EXAMPLE:

An example is demonstrated in main(). Running the script will show the
output. The plaintext sample used is: "I am Bob.". This is converted into
a binary string, an OTP is generated of the same length, the two binary
strings are then XORed, and the result can be transformed into ciphertext (ASCII).

Sample output:

Plaintext (ASCII)            I am Bob.
Plaintext (binary)           010010010010000001100001011011010010000001000010011011110110001000101110
OTP/key                      110111001111110010100100011101011101110110001101011100001000001001100000
Ciphertext (binary)          100101011101110011000101000110001111110111001111000111111110000001001110
Decrypted message (binary)   010010010010000001100001011011010010000001000010011011110110001000101110
Decrypted message (ASCII)    I am Bob.

J.A., xrzfyvqk_k1jw@pm.me
'

set -Eeo pipefail

function print_usage() {
    echo -e "otp_crypt: demo and utility functions for one-time pad encryption/decryption.
    Usage:
    ./${0##*/}             Execute demo
    ./${0##*/} [ -h ]      Print usage and exit\n"
}

function ascii_to_binary() {
    echo -n "$@"      |
    xxd -b            |
    cut -d ' ' -f 2-7 |
    tr '\n' ' '       |
    tr -d ' '
}

function binary_to_ascii(){
    string=$(echo $1 | sed 's/.\{8\}/&\ /g')
    for i in $string; do
        echo "obase=16; ibase=2; $i" |
        bc                           |
        tr '\n' ' '                  |
        xxd -r -p
    done;
}

function xor() {
    string1=$(echo $1 | tr -d ' ')
    string2=$(echo $2 | tr -d ' ')

    if [ "${#string1}" -ne "${#string2}" ]; then
        echo 'Strings are not of equal length!'
        return 1
    else
        for i in `seq 1 ${#string1}`; do
            [ "${string1:$((i-1)):1}" == "${string2:$((i-1)):1}" ] && echo -n '0' || echo -n '1'
        done
    fi
}

function generate_otp() {
    for i in `shuf -i 1-${#1}`; do
        echo -n $((i % 2))
    done
}

function main() {
    # parse
    while getopts 'h' option; do
        case $option in
            h) print_usage;  exit 0 ;;
            *) echo -e 'Incorrect usage! See below:\n'; 
               print_usage;  exit 1 ;;
        esac
    done

    # demo
    plaintext='I am Bob.'
    P=`ascii_to_binary "$plaintext"`
    key=`generate_otp "$P"`
    C=`xor "$P" "$key"`
    ciphertext=`binary_to_ascii "$C"`

    decrypted=`xor "$C" "$key"`
    recovered=`binary_to_ascii "$decrypted"`

    filetmp=`mktemp /tmp/filetmp.XXXXXX`

    echo "Plaintext (ASCII): $plaintext" >> "$filetmp"
    echo "Plaintext (binary): $P" >> "$filetmp"
    echo "OTP/key: $key" >> "$filetmp"
    echo "Ciphertext (binary): $C" >> "$filetmp"
    echo "Decrypted message (binary): $decrypted" >> "$filetmp"
    echo "Decrypted message (ASCII): $recovered" >> "$filetmp"

    cat "$filetmp" | column -t -s ':'
    rm "$filetmp"
}

main "$@"
