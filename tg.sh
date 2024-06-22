#!/usr/bin/env bash
: ' random web traffic generator - kill process w/ Ctrl+C to end script
'

if [ ! -f config.json ]; then
    echo "Could not find 'config.json'. Exiting ..."
    exit 1
fi

export root_urls=$(jq '.root_urls' config.json |
                   grep -o '"[^"]*"'           |
                   grep -o '[^"]*')

export user_agents=$(jq '.user_agents' config.json |
                     grep -o '"[^"]*"'             |
                     grep -o '[^"]*')

export max_depth=3

__tg__choose_item () { :; }
__tg__fetch_url   () { :; }
__tg__get_urls    () { :; }

__tg__choose_item() {

    local input="${1}"

    n_items=$(echo "${input}" | wc -l)

    line_number=$(shuf -i 1-${n_items} -n 1)

    item=$(echo "${input}" | sed -n "${line_number} p")

    echo "${item}"
}

__tg__fetch_url() {

    local url="${1}"

    user_agent=$(__tg__choose_item "${user_agents}")

    times=$(seq 0 9)

    time=$(__tg__choose_item "${times}")

    sleep 1."$time"  # in [1.0-1.9]

    echo "[*] URL: ${url}"
    echo "[-] USER AGENT: ${user_agent}"

    wget -O ./file_html -q \
         -e robots=off \
         -np --user-agent="${user_agent}" \
         "${url}"
}

__tg__get_urls() {

    local file_html="${1}"

    blacklist='
    .svg | .jpg | .jpeg | .png  | .tif  | .tiff | .bmp | .gif |
    .iso | .zip | .rar  | .bz2  | .gz   | .tar  | .exe |
    .mp3 | .mp4 | .mpeg | .wma  | .webm | .avi  |
    .css | .ico | .xml  | .json |
    .doc | .xls | .ppt'

    blacklist=$(echo "${blacklist}" | xargs)

    urls=$(cat "${file_html}"         |
           grep -o 'href="http[^"]*"' |
           grep -o 'http[^"]*'        |
           grep -v "${blacklist}")

    echo "${urls}"
}

trap 'rm ./file_html 2>/dev/null; exit' INT TERM EXIT

while :; do
    echo "depth 0 (root URL)..."
    url=$(__tg__choose_item "${root_urls}")
    __tg__fetch_url "${url}"
    urls=$(__tg__get_urls file_html)

    if [ -z "${urls}" ]; then
        continue
    fi

    for i in $(seq 1 ${max_depth}); do
	echo "depth ${i}..."
        url=$(__tg__choose_item "${urls}")
        __tg__fetch_url "${url}"
        urls=$(__tg__get_urls file_html)

        if [ -z "${urls}" ]; then
            break
        fi

    done
done
