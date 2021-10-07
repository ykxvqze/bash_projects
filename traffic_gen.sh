#!/usr/bin/env bash
: '
Generate random web traffic

Usage:  ./traffic_gen.sh

ARGS:
        None: N/A

OUTPUT:

        None: extracted html files will be stored in /tmp/random_traffic

DESCRIPTION:

Generate random web traffic by querying the DuckDuckGo search engine with phrases
of random length (2-6 words) constructed by picking words randomly from a
built-in dictionary (/usr/share/dic/words). Fetching is done minimally with wget, 
and the user-agent is set apriori. The interval between successive downloads is set to be
random (between 30 and 90 seconds). The script can be run in the background. Note that
the use of wget in the script can be extended to pursue links within each page recursively
to a specified depth. Default kill time for the script is 1 hour.

J.A., xrzfyvqk_k1jw@pm.me
'

user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0"
max_count=$(cat /usr/share/dict/words | wc -l)
endtime=$((`date +%s` + 60*60))
 
while [ $(date +%s) -le "$endtime" ]; do
    wait_time=$(shuf -i 30-90 -n 1)
    n_words=$(shuf -i 2-6 -n 1)
    unset x

    for i in `seq 1 $n_words`; do
        idx=$(shuf -i 1-"$max_count" -n 1)
        x[$((i-1))]=$(head -"$idx" /usr/share/dict/words | tail -1)
    done

    random_phrase=`echo ${x[*]}`

    wget -P /tmp/random_traffic -e robots=off -np -x --user-agent="$user_agent" "https://duckduckgo.com/$random_phrase"
    sleep "$wait_time"
done
