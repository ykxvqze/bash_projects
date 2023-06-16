#!/usr/bin/env bash
: '
Create line breaks at a limit of 72 characters without breaking any word

USAGE:  ./linecutter.sh [ -r | --rm ] <filename(s)>

ARGS:
        input file(s): ASCII text file(s)

OUTPUT:
        file(s): If -r or --rm switch is specified anywhere, original
                 file(s) will be overwritten. Otherwise, the result(s)
                 will be saved as new file(s) with prefix __ i.e.
                 <__filename>, and the original files remain intact.

DESCRIPTION:

If a line happens to extend beyond 72 characters, a newline character is
added at a position that is possibly lower but closest to the 72nd
character in such a way as not to break any words. Internal steps of the
method are described below:

1. Append a string marker to the file so that line-by-line processing
stops when the marker is reached, allowing the script to end.

2. Starting with the first line of the document, if the length of the
line is greater than 72 characters, then the maximum-length pattern
consisting of at most 72 characters followed by whitespace will be
replaced by those same characters, plus a newline appended. The file has
now increased by 1 line, and the result is saved _in-place_ in the file.

3. The line counter is incremented, and the previous condition is
checked again for the next line. This is repeated line-by-line until the
end-of-file marker is reached.

4. The last line of the document (containing the marker) is removed.

Why 72 characters? Because it ensures readability on most screens.

Note-1: linecutter.sh will not do anything special to lines that
originally contain indentations. 

Note-2: filenames normally must not contain any spaces.

Note-3: In Vim, the same can be done internally via:
:setl tw=72 followed by the key sequence: gg gq G

EXAMPLE:

Below is a sample text from an input file and the resulting output.

Input:

Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur. Quis aute iure
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint obcaecat cupiditat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

Output:

Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod
tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam,
nisi ut aliquid ex ea commodi consequatur. Quis aute iure reprehenderit
in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint obcaecat cupiditat non proident, sunt in culpa qui
officia deserunt mollit anim id est laborum.

J.A., ykxvqz@pm.me
'

print_usage() {
    echo -e "linecutter: cut lines at 72 characters w/o breaking words.
    Usage:
    ./${0##*/} <filename(s)>                keep original file(s) intact
    ./${0##*/} [ -r | --rm ] <filename(s)>  overwrite original file(s)
    ./${0##*/} [ -h | --help ]              Print usage and exit\n"
}

cut_lines(){
    local fileinput="$1"
    local marker='!EOF'
    echo "$marker" >> "$fileinput"
    
    i=1
    while [ "$(head -n $i "$fileinput" | tail -1)" != "$marker" ]; do
        if [ "$(sed -n "$i p" "$fileinput" | wc -c)" -gt 72 ]; then
            sed -i "$i s/^\(.\{0,72\}\)\s/\1\n/" "$fileinput"
        fi
        let i++
    done
    sed -i '$ d' "$fileinput"
}

main(){
    if [ "$#" -eq 0 ]; then
        print_usage
        exit 1
    fi

    # parse and collect filenames in an array
    args=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h | --help ) print_usage                ; exit 0 ;;
            -r | --rm   ) keep='off'                 ; shift  ;;
            -*          ) echo "Option unknown: $1"  ; exit 1 ;;
             *          ) args+=("$1")               ; shift  ;;
        esac
    done

    for i in "${args[@]}"; do
        if [ "$keep" != 'off' ]; then
            cp "$i" `dirname "$i"`/__`basename "$i"`
            cut_lines `dirname "$i"`/__`basename "$i"`
        else
            cut_lines "$i"
        fi
    done
}

main "$@"
