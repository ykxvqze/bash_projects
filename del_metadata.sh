#!/usr/bin/env bash
: '
Delete docx (Word) file metadata

Usage:  ./del_metadata.sh file1.docx file2.docx file3.docx ... fileN.docx

ARGS:
        filenames: Word documents of form [file_basename].docx  

OUTPUT:

        files ([file_basename]_cleared.docx) with metadata removed, in current directory

DESCRIPTION:

Delete metadata (author name and date timestamps) from a docx (Word) 
document, which is basically a zip file of xml documents. 
The script modifies document.xml and comments.xml (if latter is present). 
Metadata in the output file will appear empty ie (no author), (no date), 
including comments in the margin which will have no author and no timestamps.

J.A., xrzfyvqk_k1jw@pm.me
'

USAGE="Usage: $0 file1.docx file2.docx file3.docx ... fileN.docx"

if [ "$#" == "0" ]; then
    echo "$USAGE"
    exit 1
fi

while (( "$#" )); do
    filepath="$1"
    cp "$filepath" "${filepath%.docx}.zip" 
    filepath=${filepath%.docx}.zip

    unzip -l "$filepath"  #list only
    unzip "$filepath" "word/document.xml" -d /tmp 
    unzip "$filepath" "word/comments.xml" -d /tmp 

    cwd=$(pwd)
    cd /tmp

    data=$(cat word/document.xml | sed -e 's/w:author=\"[^"]*\"/w:author=""/g' -e 's/w:date=\"[^"]*\"/w:date=""/g')
    echo $data > word/document.xml
  
    if [ -f word/comments.xml ]; then
        data=$(cat word/comments.xml | sed -e 's/w:author=\"[^"]*\"/w:author=""/g' -e 's/w:date=\"[^"]*\"/w:date=""/g')
        echo "$data" > word/comments.xml
    fi

    zip --update "$cwd/$filepath" "word/document.xml"
    zip --update "$cwd/$filepath" "word/comments.xml"

    rm -fr ./word
    cd "$cwd" 
    mv "$filepath" "${filepath%.zip}_cleared.docx"

    shift
done
