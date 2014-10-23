#!/bin/bash
#
# This script gets the beautiful wallpapers from http://wallhaven.cc
# This script is brought to you by MacEarl and is based on the
# script for wallbase.cc (https://github.com/sevensins/Wallbase-Downloader)
#
#
# This Script is written for GNU Linux, it should work under Mac OS
#
#
# Revision 0.1.1
# 1. updated and tested parts of the script to work with 
#    newest wallhaven site (not all features tested)
#
# Revision 0.1
# 1. first Version of script, most features from the wallbase 
#    script are implemented
#
##################################
###    Needed for NSFW/New     ###
##################################
# Enter your Username
USER=""
# Enter your password
PASS=""
#################################
###  End needed for NSFW      ###
#################################


#################################
###   Configuration Options   ###
#################################
# Where should the Wallpapers be stored?
LOCATION=/home/nykouze/test
# How many Wallpapers should be downloaded, should be multiples of 24 (right now they only use a fixed number of thumbs per page)
WPNUMBER=60000
# Type standard (newest, oldest, random, hits, mostfav), search, favorites, useruploads, refresh
TYPE=refresh
# From which Categories should Wallpapers be downloaded
CATEGORIES=111
# Which Purity Wallpapers should be downloaded
PURITY=111
# Which Resolution should be downloaded, leave empty for all
RESOLUTION=
# Which aspectratio should be downloaded, leave empty for all
RATIO=
# Which Type should be displayed (relevance, random, date_added, views, favorites)
SORTING=date_added
# How should the Wallpapers be ordered (desc, asc)
ORDER=desc
# Searchterm
QUERY="nature"
# User from which Wallpapers should be downloaded (only used for TYPE=useruploads)
USR=AksumkA
#################################
### End Configuration Options ###
#################################
 
if [ ! -d $LOCATION ]; then
    mkdir -p $LOCATION
fi

cd $LOCATION

#
# logs in to the wallhaven website to give the user more functionality
# requires 2 arguments:
# arg1: username
# arg2: password
#
function login {
    # checking parameters -> if not ok print error and exit script
    if [ $# -lt 2 ] || [ $1 == '' ] || [ $2 == '' ]; then
        printf "Please check the needed Options for NSFW Content (username and password)\n\n"
        printf "For further Information see Section 13\n\n"
        printf "Press any key to exit\n"
        read
        exit
    fi
    
    # everythings ok --> login
    wget -q --keep-session-cookies --save-cookies=cookies.txt --referer=http://alpha.wallhaven.cc http://alpha.wallhaven.cc/auth/login
    token="$(cat login | grep 'name="_token"' | sed  's .\{180\}  ' | sed 's/.\{16\}$//')"
    wget -q --load-cookies=cookies.txt --keep-session-cookies --save-cookies=cookies.txt --referer=http://alpha.wallhaven.cc/auth/login --post-data="_token=$token&username=$USER&password=$PASS" http://alpha.wallhaven.cc/auth/login
} # /login

# 
# downloads Page with Thumbnails 
#
function getPage {
    # checking parameters -> if not ok print error and exit script
    if [ $# -lt 1 ]; then
        printf "getPage expects at least 1 argument\n"
        printf "arg1:    parameters for the wget -q command\n\n"
        printf "press any key to exit\n"
        read
        exit
    fi

    # parameters ok --> get page
    wget -q --keep-session-cookies --load-cookies=cookies.txt --referer=alpha.wallhaven.cc -O tmp "http://alpha.wallhaven.cc/$1"
    # echo "http://alpha.wallhaven.cc/$1"
    # cat tmp
} # /getPage

#
# downloads all the wallpapers from a wallpaperfile
# arg1: the file containing the wallpapers
#
function downloadWallpapers {
	URLSFORIMAGES="$(cat tmp | grep -o '<a class="preview" href="http://alpha.wallhaven.cc/wallpaper/[0-9]*"' | sed  's .\{25\}  ')"
        readarray -t sorted < <(for a in "${URLSFORIMAGES[@]}"; do echo "$a"; done | sort -r)
	for imgURL in $sorted
        do
        img="$(echo $imgURL | sed 's/.\{1\}$//')"
	number="$(echo $img | sed  's .\{36\}  ')"
#	echo "number: $number"
        img="$(echo http://alpha.wallhaven.cc/wallpapers/full/wallhaven-$number.jpg)"
#	echo "img: $img"
	if cat downloaded.txt | grep -w "$number" >/dev/null
			then
				printf "File already downloaded!\n"
				if [ $TYPE == refresh ]; then
				  rm -f cookies.txt login login.1 tmp
				  printf "    - done!\n"
				  exit 0
                                fi
			else
				echo $number >> downloaded.txt
				wget -q --keep-session-cookies --load-cookies=cookies.txt --referer=alpha.wallhaven.cc $img
				#cat $number | egrep -o "http://alpha.wallhaven.cc/wallpapers.*(png|jpg|gif)" | wget -q --keep-session-cookies --load-cookies=cookies.txt --referer=http://alpha.wallhaven.cc/wallpapers/$number -i -
				#rm $number
        fi
        done
        rm tmp
} #/downloadWallpapers

# login only when it is required ( for example to download favourites or nsfw content... )
#if [ $PURITY == 001 ] || [ $PURITY == 011 ] || [ $PURITY == 111 ] ; then
#   login $USER $PASS
#fi

if [ $TYPE == refresh ]; then
  SORTING=date_added
  ORDER=desc
fi

if [ $TYPE == standard ] || [ $TYPE == refresh ]; then
    for (( count= 0, page=1; count< "$WPNUMBER"; count=count+24, page=page+1 ));
    do
        printf "Download Page $page"
        getPage "search?page=$page&categories=$CATEGORIES&purity=$PURITY&resolutions=$RESOLUTION&ratios=$RATIO&sorting=$SORTING&order=$ORDER"
        printf "                    - done!\n"
        printf "Download Wallpapers from Page $page"
        downloadWallpapers
        printf "    - done!\n"
    done

elif [ $TYPE == search ] ; then
    # SEARCH
    for (( count= 0, page=1; count< "$WPNUMBER"; count=count+24, page=page+1 ));
    do
        printf "Download Page $page"
        getPage "wallpaper/search?page=$page&categories=$CATEGORIES&purity=$PURITY&resolutions=$RESOLUTION&ratios=$RATIO&sorting=relevance&order=desc&q=$QUERY"
        printf "                    - done!\n"
        printf "Download Wallpapers from Page $page"
        downloadWallpapers
        printf "    - done!\n"
    done
    
elif [ $TYPE == favorites ] ; then
    # FAVORITES
    # currently using sum of all collections
    favnumber="$(wget -q --keep-session-cookies --load-cookies=cookies.txt --referer=alpha.wallhaven.cc http://alpha.wallhaven.cc/favorites -O - | grep -A 1 "<span>Favorites</span>" | grep -B 1 "<small>" | sed -n '2{p;q}' | sed 's/.\{9\}$//' | sed 's .\{23\}  ')"
    for (( count= 0, page=1; count< "$WPNUMBER" && count< "$favnumber"; count=count+24, page=page+1 ));
    do
        printf "Download Page $page"
        getPage "favorites?page=$page"
        printf "                    - done!\n"
        printf "Download Wallpapers from Page $page"
        downloadWallpapers
        printf "    - done!\n"
    done

elif [ $TYPE == useruploads ] ; then
    # UPLOADS FROM SPECIFIC USER
    for (( count= 0, page=1; count< "$WPNUMBER"; count=count+24, page=page+1 ));
    do
        printf "Download Page $page"
        getPage "user/$USR/uploads?page=$page"
        printf "                    - done!\n"
        printf "Download Wallpapers from Page $page"
        downloadWallpapers
        printf "    - done!\n"
    done

else
    printf "error in TYPE please check Variable\n"
fi

rm -f cookies.txt login login.1
