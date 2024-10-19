#!/usr/bin/env bash
: '
Scrape images iteratively from the xkcd site. Continue from last fetch upon script re-run.

USAGE:  ./scrapexkcd.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
        * Image files (e.g. *.jpg or *.png) saved in ./xkcd/ directory.
        * A file named log_counter containing a single integer, useful
          for keeping track of the last page scraped so that re-runs of the
          script begin from where it left off (instead of from first page).

DESCRIPTION:

Images on xkcd.com can be viewed with URL: https://xkcd.com/<i>/index.html
where <i> is an integer from 1 to some number which increases as more
images are added with time.

The Nginx web server directory holding the images has no read permission
(403 forbidden): https://imgs.xkcd.com/comics/

The image files, however, can still be downloaded if their filenames are
known. Hence, the filenames would first need to be discovered, i.e.,
scraped from index.html file on each page.

This script fetches each index.html file by looping over <i> and then
detects a URL pattern in the file pointing to the main image presented.
The loop increments indefinitely until it fails to find an
index.html file for some <i>. The images are stored in a directory
named xkcd under the current directory from where the script is executed
(./xkcd/). If the directory does not already exist, it will be created
and fetching will begin at i=1. The script will also save a file named
log_counter in the mentioned directory to keep track of the counter <i>.
This way, if the script is re-run some other time, it will start
scraping based on the last index.html file it already scraped in the
previous execution. Hence, it will fetch only new images, adding them to
./xkcd/
'

trap 'echo error on line: $LINENO' ERR

print_usage() {
    echo -e "scrapexkcd.sh: fetch cartoon images from the xkcd site iteratively.
    Usage:
    ./${0##*/}             Execute script and fetch images into ./xkcd directory
    ./${0##*/} [ -h ]      Print usage and exit\n"
}

while getopts 'h' option; do
    case $option in
        h) print_usage;  exit 0 ;;
        *) echo -e 'Incorrect usage! See below:\n';
           print_usage;  exit 1 ;;
    esac
done

if [ -d ./xkcd ]; then
    echo 'Directory ./xkcd already exists.'
else
    echo 'Creating directory ./xkcd'
    mkdir ./xkcd
fi

if [ -f ./xkcd/log_counter ]; then
    echo 'Last logged site counter exists.'
else
    echo 'Last logged site counter does not exist.'
    echo 'Will start newly from: i=1...'
    echo 1 > ./xkcd/log_counter
fi

i=$(cat ./xkcd/log_counter)
while : ; do
    if [ -f ./xkcd/index.html ]; then
        rm ./xkcd/index.html
    fi

    echo "webpage counter: $i"
    wget -q -P './xkcd' "https://xkcd.com/$i/index.html"

    if [ "$?" -ne 0 ]; then
        echo 'Reached final page. Exiting...'
        break
    fi

    url_of_image=$(grep 'Image URL (for hotlinking/embedding):' ./xkcd/index.html |
                   grep -o '"https://imgs.xkcd.com/comics/[^"]*"'                 |
                   sed 's/"//g')
    echo "Fetching $url_of_image ..."
    wget -q -P './xkcd' "$url_of_image"
    let i++
    echo "$i" > ./xkcd/log_counter
done
