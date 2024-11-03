#!/usr/bin/env bash
: '
Clear Firefox data, bookmarks, cookies, cache, and other files

USAGE:  ./clr.sh [ -h ]

OPTIONS:
        [ -h ]         Print usage and exit

OUTPUT:
        N/A

DESCRIPTION:

A script that can be set as a cron job for browser and other cache cleanup.
It iterates over existent Firefox profiles and recursively clears cache
and other files within target directories. Patterns sought include:
`cookies`, `places`, `history`, `webappsstore`, and `bookmarks`,
`datareporting`, `bookmarkbackups`. System thumbnail cache located at
~/.cache/thumbnails is also cleared.
'

trap 'echo error on line: $LINENO' ERR

print_usage() {
    echo -e "clr.sh: clear Firefox cache, cookies, and other files.
    Usage:
          ./${0##*/}
          ./${0##*/} [ -h ]    Print usage and exit\n"
}

while getopts 'h' option; do
    case $option in
        h) print_usage;  exit 0 ;;
        *) echo -e 'Incorrect usage. See below:\n';
           print_usage;  exit 1 ;;
    esac
done

# Firefox
cd ~/.cache/mozilla/firefox/
find . -type f ! -path "./*/settings/*"     \
               ! -path "./*/startupCache/*" \
               ! -path "./*/safebrowsing/*" \
                 -exec bash -c '>"{}"'      \;

cd ~/.mozilla/firefox/
find . -type f -name "cookies*"      \
            -o -name "places*"       \
            -o -name "*history*"     \
            -o -name "webappsstore*" \
            -o -name "bookmarks*"    \
               -exec bash -c '>"{}"' \;

find . -type f -path "./*/datareporting/*"    \
            -o -path "./*/bookmarkbackups/*"  \
               -exec bash -c '>"{}"; rm "{}"' \;

# other
cd ~/.cache/thumbnails
find . -type f -exec bash -c '>"{}"; rm "{}"' \;

<< 'EOF'
cd ~/.cache/thunderbird/
find . -type f -exec bash -c '>"{}"; rm "{}"' \;

# custom temp folder
cd ~/Documents/temp
find . -type f -exec bash -c '>"{}"; rm "{}"' \;
rm -rf ~/Documents/temp
EOF
