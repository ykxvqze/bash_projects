#!/usr/bin/env bash
: '
Scrape cartoon images iteratively from the xkcd site. Continue from last fetch upon script re-run.

USAGE:  ./scrape_xkcd.sh [ -h ]

OPTIONS:
        [ -h ]  Print usage

OUTPUT:
        Image files (e.g. *.jpg or *.png) saved in ./xkcd/ directory.
        A file named `log_site_counter` containing a single integer, useful
        for keeping track of the last page scraped so that re-runs of the
        script commence from where it left off (instead of from first page).

DESCRIPTION:

Comic cartoons on xkcd.com can be viewed with URL: https://xkcd.com/<i>/index.html
where <i> is an integer from 1 to some number (which increases as more
cartoons are added with time).

The nginx web server directory holding the images has no read permission:
https://imgs.xkcd.com/comics/      # 403 Forbidden

The image files however can still be downloaded if their filenames are
known; hence, the filenames would first need to be discovered (i.e.
scraped from `index.html` files).

This script fetches each `index.html` file by looping over <i> and then
detects a URL pattern in the file pointing to the main cartoon image
presented. The loop increments indefinitely until it fails to find an
`index.html` file for some <i>. The images are stored in a specific
directory under the current one from which the script is executed: ./xkcd/
If the directory does not already exist, it will be created and fetching
will begin at i=1. The script will also save a file named `log_site_counter`
in the mentioned directory to keep track of the counter <i>. This way,
if the script is re-run on some other day, it will start scraping from
the last `index.html` it already scraped in the previous execution. Hence,
it will fetch only new cartoon images adding them to ./xkcd/

J.A., xrzfyvqk_k1jw@pm.me
'

trap 'echo error on line: $LINENO' ERR

print_usage() {
    echo -e "scrape_xkcd: fetch cartoon images from the xkcd site iteratively.
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

if [ -f ./xkcd/log_site_counter ]; then
    echo 'Last logged site counter exists. Reading counter...'
    i=`cat ./xkcd/log_site_counter`
else
    echo 'Last logged site counter does not exist.'
    echo 'Will start anew from: i=1...'
    echo 1 > ./xkcd/log_site_counter
fi

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

    url_of_image=`grep 'Image URL (for hotlinking/embedding):' ./xkcd/index.html |
                  grep -o '"https://imgs.xkcd.com/comics/[^"]*"'                 |
                  sed 's/"//g'`
    echo "Fetching $url_of_image..."
    wget -q -P './xkcd' "$url_of_image"
    let i++
    echo "$i" > ./xkcd/log_site_counter
done
