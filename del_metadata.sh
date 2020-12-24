#!/bin/bash
: '
Delete docx (Word) file metadata

Usage: ./del_metadata [file_basename].docx 

ARGS:
		filename (with docx): Word document , i.e. [file_basename].docx  

OUTPUT:   
       
		file ([file_basename]_cleared.docx) with metadata removed

DESCRIPTION:

Deletes metadata (author name and date timestamps) from a docx (Word) 
document, which is basically a zip file of xml documents. 
The script modifies document.xml and comments.xml (if present). 
Metadata in the output file will appear empty (no author), (no date), including
comments in the margin which will have no author and no timestamps.   

J.A., xvnyjlq@yandex.com
'

filepath=${@: -1}  #or ${@:$#} or ${!#} or $BASH_ARGV  (last argument)
mask=$1

cp "$filepath" "${filepath%.docx}.zip" 
filepath=${filepath%.docx}.zip

unzip -l $filepath #list only

unzip "$filepath" "word/document.xml" -d /tmp 
unzip "$filepath" "word/comments.xml" -d /tmp 

cwd=$(pwd)
cd /tmp

data=$(cat word/document.xml) #subshell
data=$(echo $data | sed 's/w:author=\"[^"]*\"/w:author=""/g') 
data=$(echo $data | sed 's/w:date=\"[^"]*\"/w:date=""/g')

echo $data > word/document.xml
  
if [ -f word/comments.xml ]
then 
	data=$(cat word/comments.xml)
	data=$(echo $data | sed 's/w:author=\"[^"]*\"/w:author=""/g') 
	data=$(echo $data | sed 's/w:date=\"[^"]*\"/w:date=""/g')
	echo $data > word/comments.xml
fi

zip --update "$cwd/$filepath" "word/document.xml"
zip --update "$cwd/$filepath" "word/comments.xml"

rm -fr word 

cd "$cwd" 
mv "$filepath" "${filepath%.zip}_cleared.docx" 
