#!/usr/bin/env bash

<< 'EOF'
Password Generator.

The password includes:

        Uppercase letters (A-Z)
        Lowercase letters (a-z)
        Numbers (0-9)
        Special characters (~`!@#$%^&*()-_+=[]{}:;|,.<>/?)

USAGE:

       ./genpass.sh <password_length>

SAMPLE OUTPUT:

       Generated Password: tS6~w=E8E|u2C%0xM8

NOTES:

       Default length (if unspecified) is 18.
       Minimum allowed length is 4.
EOF

__print_usage           () { :; }
__parse_options         () { :; }
__parse_arguments       () { :; }
__validate_nargs        () { :; }
__validate_args         () { :; }
__set_character_classes () { :; }
__generate_password     () { :; }
__main                  () { :; }

__print_usage() {
    echo -e "Password generator.

             USAGE:
                   ./${0##*/} <password_length>

                   ./${0##*/} 12 \n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage; exit 0;;
            *) echo "Invalid option. Exiting..."; exit 1;;
        esac
    done
}

__parse_arguments() {
    password_length="${1}"

    if [[ -z "${password_length}" ]]; then
        password_length=18
    fi
}

__validate_nargs() {
    if [[ "$#" -gt 1 ]]; then
        echo "Invalid number of arguments."
        exit 1
    fi
}

__validate_args() {
    if [[ ! "${password_length}" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: password length must be a positive integer."
        exit 1
    elif [[ "${password_length}" -lt 4 ]]; then
        echo "Error: password length must be at least 4."
        exit 1
    fi
}

__set_character_classes() {
    characters_uppercase=($(echo {A..Z}))
    characters_lowercase=($(echo {a..z}))
    characters_digits=($(echo {0..9}))
    characters_special=('~' '`' '!' '@' '#' '$' '%' '^' '&' '*' '(' ')' '-' '_' '+' '=' '[' ']' '{' '}' ':' ';' '|' ',' '.' '<' '>' '/' '?')

    n_characters_uppercase="${#characters_uppercase[@]}"
    n_characters_lowercase="${#characters_lowercase[@]}"
    n_characters_digits="${#characters_digits[@]}"
    n_characters_special="${#characters_special[@]}"
}

__generate_password() {
    __set_character_classes

    password=''

    n_char="${password_length}"

    while [[ "${n_char}" -gt 0 ]]; do

        classes="$(shuf -i 1-4)"

        for i in $classes; do
            case "$i" in
                1) index="$(shuf -i 1-"$n_characters_uppercase" -n 1)"
                   password+="${characters_uppercase[((index-1))]}"
                   ((n_char--))

                   if [[ "${n_char}" -eq 0 ]]; then
                       break 2
                   fi;;

                2) index="$(shuf -i 1-"$n_characters_lowercase" -n 1)"
                   password+="${characters_lowercase[((index-1))]}"
                   ((n_char--))

                   if [[ "${n_char}" -eq 0 ]]; then
                       break 2
                   fi;;

                3) index="$(shuf -i 1-"$n_characters_digits" -n 1)"
                   password+="${characters_digits[((index-1))]}"
                   ((n_char--))

                   if [[ "${n_char}" -eq 0 ]]; then
                       break 2
                   fi;;

                4) index="$(shuf -i 1-"$n_characters_special" -n 1)"
                   password+="${characters_special[((index-1))]}"
                   ((n_char--))

                   if [[ "${n_char}" -eq 0 ]]; then
                       break 2
                   fi;;
            esac
        done
    done

    echo "Generated password: ${password}"
}

__main() {
    __validate_nargs "$@"
    __parse_options "$@"
    __parse_arguments "$@"
    __validate_args
    __generate_password
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    __main "$@"
fi
