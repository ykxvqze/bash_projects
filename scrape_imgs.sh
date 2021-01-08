#!/bin/bash
:'
Download all cartoon images from (inaccessible) xkcd.com directory; 
(can be adapted to similar situations)

Usage: ./scrape_xkcd.sh	path_to_directory 
		
		if unspecified, path_to_directory will be default: ~/Downloads/xkcd_imgs/
	   
ARGS:
		none  

OUTPUT:   
       
		image files (*.jpg or *.png) in path_to_directory

DESCRIPTION:

Observation: comic cartoons on xkcd.com can be viewed with URL: 

https://xkcd.com/[i]/index.html

where [i] is an integer from 1 to some number (which increases as more cartoons are added over time)

The cartoon image files can be downloaded one at a time by visiting all 
consecutive index.html files, however the number of cartoons so far is a few thousands (>4000), 
and the directory on the web server which holds these images is forbidden: 

https://imgs.xkcd.com/comics/  ->  #403 Forbidden

With no permission to access the directory, its image files can still be
downloaded with wget if their filenames are known; so these filenames 
would first need to be detected, ie scraped from index.html files. 

Observation: inspecting a few index.html files, the cartoon images are located at: 
 
https://imgs.xkcd.com/comics/*.jpg	
or 
https://imgs.xkcd.com/comics/*.png

where * represents some variable filename for each cartoon.

This script fetches index.html files by incrementing [i] in a loop and detecting
the URL in the html files pointing to the cartoon image (jpg or png file). 
The loop increments indefinitely until it fails to find an index.html file for some [i]. 
The images are stored in a specified directory or by default in ~/Downloads/xkcd_imgs/ 

J.A., xvnyjlq@yandex.com
'

if [ $# = 0 ]
then
	loc="$HOME/Downloads/xkcd_imgs"    
else
	loc=$1
fi

cwd=$(pwd)
cd /tmp

flag=0; i=1
while [ flag=0 ]     
do
	echo site_count: $i
	wget "https://xkcd.com/$i/index.html"  
	flag=$?
	wget -P $loc $(grep -o 'https://imgs.xkcd.com/comics/.*.[jpg|png]' index.html)
	rm /tmp/index.html   
	let i++
done

cd "$cwd" 
