#!/usr/bin/env bash
: ' traffic generator (kill script to end session w/ Ctrl+C)

J.A., ykxvqz@pm.me
'

export root_urls=`jq '.root_urls' config.json |
                  grep -o '"[^"]*"'           |
                  grep -o '[^"]*'`

export user_agents=`jq '.user_agents' config.json |
                    grep -o '"[^"]*"'             |
                    grep -o '[^"]*'`

export max_depth=3

__tg__get_urls    () { :; }
__tg__choose_item () { :; }
__tg__fetch_url   () { :; }

__tg__get_urls() {

    local file_html="$1"

    blacklist='
    .svg | .jpg | .jpeg | .png  | .tif  | .tiff | .bmp | .gif |
    .iso | .zip | .rar  | .bz2  | .gz   | .tar  | .exe |
    .mp3 | .mp4 | .mpeg | .wma  | .webm | .avi  |
    .css | .ico | .xml  | .json |
    .doc | .xls | .ppt'

    blacklist=`echo "$blacklist" | xargs`

    urls=`cat "${file_html}"         |
          grep -o 'href="http[^"]*"' |
          grep -o 'http[^"]*'        |
          grep -v "$blacklist"`

    echo "$urls"
}

__tg__choose_item() {

    local input="$1"

    n_items=`echo "$input" | wc -l`

    line_number=`shuf -i 1-${n_items} -n 1`

    item=`echo "$input" | sed -n "${line_number} p"`

    echo "$item"
}

__tg__fetch_url() {

    local url="$1"

    user_agent=`__tg__choose_item "$user_agents"`

    times=`seq 0 9`

    time=`__tg__choose_item "$times"`

    sleep 1."$time"  # in [1-1.9]

    echo "[*] `date +'%d-%m-%Y %H:%M:%S'`: $url"
    echo "    >> user_agent: $user_agent"
    wget -O ./file_html -q \
         -e robots=off \
         -np --user-agent="${user_agent}" \
         "$url"
}

trap 'rm ./file_html 2>/dev/null; exit' INT TERM EXIT

while :; do
    url=`__tg__choose_item "${root_urls}"`
    __tg__fetch_url "$url"
    urls=`__tg__get_urls file_html`

    for i in `seq 1 $max_depth`; do
        url=`__tg__choose_item "$urls"`
        __tg__fetch_url "$url"
        urls=`__tg__get_urls file_html`
    done
done
