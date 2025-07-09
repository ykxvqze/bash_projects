#!/usr/bin/env bash

<< 'EOF'
Delete .docx (Word) file metadata

USAGE:  ./delmeta.sh <file1.docx> <file2.docx> ... <fileN.docx>

OPTIONS:
       -h    Print usage and exit

ARGS:
        filename(s): Word document(s) with filename format: <basename>.docx
                     Filenames may include paths, e.g. /dir/subdir/file1.docx
                     Multiple filenames should be delimited by space and
                     a filename should not begin with a hyphen (-)

OUTPUT:
        files (<basename>_formatted.docx) with metadata removed in the
        same directory as the original (input) files.

DESCRIPTION:

Delete metadata (author name and date/timestamps) from a docx document
which is basically a zip file of XML documents. The script modifies
document.xml and comments.xml (if latter is present). Metadata in the
output file will appear empty i.e. (no author), (no date), including any
comments in the margin, which will appear with no author and no timestamps.

Note: the script automatically checks for the .docx extension at the end
of a filename or path and will not process a file if it lacks the extension.

Note: do the below _before_ running this script on a *.docx file.
Open the .docx file in libreoffice and "Save As" a .docx file to obtain a
libreoffice-based version, then "Close" the files. Open the new file and
"Save" it. The "Save As" step is important as other attempts may corrupt
the original .docx file. "Save As" leaves the original file intact. Now you
can run ./delmeta.sh on the new file. The resulting formatted file will
be readable in both libreoffice and Word and will be stripped of metadata.
EOF

__set_trap      () { :; }
__print_usage   () { :; }
__get_abspath   () { :; }
__check_nargs   () { :; }
__parse_options () { :; }
__process_files () { :; }
__main          () { :; }

set_trap() {
    trap 'echo error on line: $LINENO' ERR
}

__print_usage() {
    echo -e "Delete author and timestamp metadata from .docx (Word) files.

    Usage:

    ./${0##*/} <filename(s).docx>  At least one filename must be supplied
    ./${0##*/} [ -h ]              Print usage and exit\n"
}

__get_abspath(){
    local file="$1"
    dname=$(dirname "$file")
    bname=$(basename "$file")
    abspath_dir=$(cd "$dname" && pwd || exit 1)
    abspath="${abspath_dir}/${bname}"
    echo "$abspath"
}

__check_nargs() {
    if [ "$#" -eq 0 ]; then
        __print_usage
        exit 1
    fi
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage;  exit 0 ;;
            *) echo -e 'Incorrect usage! See below:\n';
               __print_usage;  exit 1 ;;
        esac
    done
}

__process_files() {
    while (( "$#" )); do
        file="$1"
        abs_path=$(__get_abspath "$file")
        dpath=$(dirname $abs_path)
        bname=$(basename $abs_path)

        if [ ! -f "$abs_path" ]; then
            echo "File $abs_path does not exist. Exiting...";
            exit 1
        fi

        if [ "${bname##*.}" != 'docx' ]; then
            echo 'File does not have a .docx extension. Exiting...'
            exit 1
        fi

        file_renamed=${abs_path%.docx}.zip
        cp "${file}" "${file_renamed}"

        dir_temp=$(mktemp -d /tmp/tempdir.XXXX)
        unzip "$file_renamed" "word/document.xml" -d "$dir_temp"
        unzip "$file_renamed" "word/comments.xml" -d "$dir_temp"

        cwd=$(pwd)
        cd "$dir_temp"

        data=$(cat word/document.xml |
               sed -e 's/w:author="[^"]*"/w:author=""/g;
                       s/w:date="[^"]*"/w:date=""/g')
        echo "$data" > word/document.xml
        zip --update "$file_renamed" "word/document.xml"

        if [ -f word/comments.xml ]; then
            data=$(cat word/comments.xml |
                   sed -e 's/w:author="[^"]*"/w:author=""/g;
                           s/w:date="[^"]*"/w:date=""/g')
            echo "$data" > word/comments.xml
            zip --update "$file_renamed" "word/comments.xml"
        fi

        cd "$cwd"
        mv "$file_renamed" "${file_renamed%.zip}_formatted.docx"
        rm -rf "$dir_temp"

        shift
    done
}

__main() {
    __set_trap
    __check_nargs "$@"
    __parse_options "$@"
    __process_files "$@"
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    __main "$@"
fi
