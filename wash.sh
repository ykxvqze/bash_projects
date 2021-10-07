#!/usr/bin/env bash
: '
Clear Firefox data, bookmarks, cookies, cache, and other files

Usage:  ./wash.sh

ARGS:
        None: N/A

OUTPUT:

        None: N/A

DESCRIPTION:

A script that can be placed as a cron job for browser data and other files cleanup. The script iterates 
over all firefox profiles, recursively clearing specific private files within all subdirectories of 
~/.mozilla/firefox. These include filenames containing the patterns: 
cookies, places, history, webappsstore, and bookmarks; examples: cookies.sqlite, places.sqlite, 
formhistory.sqlite, webappsstore.sqlite. Also, all files within the directories */datareporting and 
*/bookmarkbackups are cleared and then removed. All files within ~/.cache/mozilla/firefox are also cleared 
except those in */settings, */startupCache, and */safebrowsing. Finally, all files in ~/.cache/thumbnails 
are cleared and removed, in addition to those in ~/Documents/temp (supposedly containing files which can be 
disposed of when needed by uncommenting the section).

J.A., xrzfyvqk_k1jw@pm.me
'

# firefox browser
cd ~/.cache/mozilla/firefox/
find . -type f ! -path "./*/settings/*" ! -path "./*/startupCache/*" ! -path "./*/safebrowsing/*" -exec bash -c '>"{}"' \; 

cd ~/.mozilla/firefox/
find . -type f -name "cookies*" -exec bash -c '>"{}"' \;
find . -type f -name "places*" -exec bash -c '>"{}"' \;
find . -type f -name "*history*" -exec bash -c '>"{}"' \;
find . -type f -name "webappsstore*" -exec bash -c '>"{}"' \;
find . -type f -name "bookmarks*" -exec bash -c '>"{}"' \; 

find . -type f -path "./*/datareporting/*" -exec bash -c '>"{}"; rm "{}"' \;
find . -type f -path "./*/bookmarkbackups/*" -exec bash -c '>"{}"; rm "{}"' \;

# other cache
cd ~/.cache/thumbnails
find . -type f -exec bash -c '>"{}"; rm "{}"' \; 

#cd ~/.cache/thunderbird/
#find . -type f -exec bash -c '>"{}"; rm "{}"' \;

# temp folder
#cd ~/Documents/temp
#find . -type f -exec bash -c '>"{}"; rm "{}"' \; 
#rm -rf ~/Documents/temp
