#!/usr/bin/env bash

<< 'EOF'
Scrape images iteratively from the xkcd site. Continue from last fetch upon script re-run.

USAGE:  ./scrapexkcd.sh [ -h ]

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
        * Image files (e.g., *.jpg or *.png) saved in ./xkcd/ directory.
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
known. Hence, the filenames need to be discovered, i.e., scraped from
the index.html file on each page.

This script fetches each index.html file by looping over <i> and then
detects a URL pattern in the file pointing to the main image presented.
The loop increments indefinitely until it fails to find an index.html
file for some <i>. The images get stored in a directory named xkcd under
the current directory from where the script is executed (./xkcd/). If
the directory does not already exist, it will be created and fetching
will begin at i=1. The script also saves a file named log_counter in the
mentioned directory to keep track of the counter <i>. This way, if the
script is re-run some other time, it will start scraping based on the
last index.html file it already scraped in the previous execution.
Hence, it will fetch only new images, adding them to ./xkcd/
EOF

__set_trap               () { :; }
__print_usage            () { :; }
__parse_options          () { :; }
__check_xkcd_directory   () { :; }
__check_log_counter_file () { :; }
__read_log_counter       () { :; }
__remove_index_page      () { :; }
__fetch_index_page       () { :; }
__check_download_status  () { :; }
__get_image_url          () { :; }
__fetch_image            () { :; }
__update_log_counter     () { :; }
__main                   () { :; }

__set_trap() {
    trap 'echo error on line: $LINENO' ERR
}

__print_usage() {
    echo -e "Fetch images from the xkcd site iteratively.
    
    Usage:
    
    ./${0##*/}             Execute script and fetch images into ./xkcd directory
    ./${0##*/} [ -h ]      Print usage and exit\n"
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

__check_xkcd_directory() {
    if [[ -d ./xkcd ]]; then
        echo "Directory ./xkcd already exists."
    else
        echo "Creating directory ./xkcd"
        mkdir ./xkcd
    fi
}

__check_log_counter_file() {
    if [[ -f ./xkcd/log_counter ]]; then
        echo "Last logged site counter exists."
    else
        echo "Last logged site counter does not exist."
        echo "Will start newly from: i=1..."
        echo 1 > ./xkcd/log_counter
    fi
}

__read_log_counter() {
    counter="$(cat ./xkcd/log_counter)"
    echo "webpage counter: $counter"
}

__remove_index_page() {
    if [[ -f ./xkcd/index.html ]]; then
        rm ./xkcd/index.html
    fi
}

__fetch_index_page() {
    wget -q -P './xkcd' "https://xkcd.com/${counter}/index.html"
}

__check_download_status() {
    if [[ "$?" -ne 0 ]]; then
        echo "Error downloading or reached final page. Exiting..."
        exit 1
    fi
}

__get_image_url() {
    url_of_image="$(grep 'Image URL (for hotlinking/embedding):' ./xkcd/index.html |
                    grep -o '"https://imgs.xkcd.com/comics/[^"]*"'                 |
                    sed 's/"//g')"
}

__fetch_image() {
    echo "Fetching $url_of_image ..."
    wget -q -P './xkcd' "$url_of_image"
}

__update_log_counter() {
    ((counter++))
    echo "${counter}" > ./xkcd/log_counter
}

__main() {
    __set_trap
    __parse_options "$@"
    __check_xkcd_directory
    __check_log_counter_file
    __read_log_counter

    while : ; do
        __remove_index_page
        __fetch_index_page
        __check_download_status
        __get_image_url
        __fetch_image
        __update_log_counter
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
