#!/usr/bin/env bash

<< 'EOF'
Create line breaks at a limit of 72 characters without breaking any word

USAGE:  ./wrapline.sh [ -i | --inplace ] <file1> <file2> ...

ARGS:
        file(s): ASCII text file(s)

OUTPUT:
        file(s): If -i or --inplace switch is specified anywhere, the
                 original file(s) will be overwritten. Otherwise, the
                 result(s) will be saved as new file(s) with a __ prefix
                 i.e. <__filename>, so the original files remain intact.

DESCRIPTION:

If a line extends beyond 72 characters, a newline character is added at
the highest position that breaks the line, leaving at most 72 characters.
Also, this is done in such a way as not to break any individual words.

Internal steps:

1. Starting with the first line of the file, if the length of the line
is greater than 72 characters, then the pattern consisting of at most
72 characters followed by whitespace will be replaced by those same
characters (without whitespace), plus a newline appended. The file will
have now increased by 1 line, and the result is saved in-place.

2. Step 1 is repeated line-by-line until the end of the file is reached.

Why 72 characters? ... because it ensures readability on most screens.

Notes:

- The script will not do anything special to lines that originally
contain indentations.

- In Vim, the same can be done internally via:
:setl tw=72 followed by the key sequence: gg gq G

- The script does similar to: fold -w 72 -s <filename>

Input:

Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur. Quis aute iure
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint obcaecat cupiditat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

Output:

Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod
tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam,
nisi ut aliquid ex ea commodi consequatur. Quis aute iure
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint obcaecat cupiditat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
EOF

__print_usage       () { :; }
__cut_lines         () { :; }
__check_nargs       () { :; }
__parse_arguments   () { :; }
__check_files_exist () { :; }
__process_files     () { :; }
__main              () { :; }

__print_usage() {
    echo -e "Wrap lines at 72 characters without breaking words.

    Usage:

        ./${0##*/} <file1> <file2> ...                     Keep original file(s) intact
        ./${0##*/} [ -i | --inplace ] <file1> <file2> ...  Change file(s) in-place
        ./${0##*/} [ -h | --help ]                         Print usage and exit \n"
}

__cut_lines() {
    local FILE="${1}"
    local n_lines="$(cat "$FILE" | wc -l)"
    local i=1

    while [[ "$i" -le "$n_lines" ]]; do
        if [[ "$(sed -n "$i p" "$FILE" | wc -c)" -gt 72 ]]; then
            sed -Ei "$i s/^(.{0,72})\s/\1\n/" "$FILE"
        fi
        let i++
        n_lines="$(cat "$FILE" | wc -l)"
    done
}

__check_nargs() {
    if [[ "$#" -eq 0 ]]; then
        __print_usage
        exit 1
    fi
}

__parse_arguments() {
    args=()
    while (("$#")); do
        case "${1}" in
            -h | --help    ) __print_usage; exit 0;;
            -i | --inplace ) inplace="true"; shift ;;
            -*             ) echo "Invalid option. Exiting..." ; exit 1;;
             *             ) args+=("${1}"); shift;;
        esac
    done
}

__check_files_exist() {
    for f in "${args[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "File $f does not exist. Exiting..."
            exit 1
        fi
    done
}

__process_files() {
    if [[ "$inplace" == "true" ]]; then
        for f in "${args[@]}"; do
            __cut_lines "$f"
        done
    else
        for f in "${args[@]}"; do
            cp "$f" "$(dirname "$f")/__$(basename "$f")"
            __cut_lines "$(dirname "$f")/__$(basename "$f")"
        done
    fi
}

__main() {
    __check_nargs "$@"
    __parse_arguments "$@"
    __check_files_exist
    __process_files
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
