#!/usr/bin/env bash
: '
Android cleanup: uninstall extraneous apps and/or replace with open-source ones.

USAGE:  ./android_cleanup.sh [ -h ]
        
                Phone must be connected by USB and debugging mode enabled
                (`Developer` options). File ./packages_to_remove.txt
                should list apps to remove (1 per line) and can be modified
                as needed. Packages to install can be modified within the
                the script by removing or adding URLs of open source apps
                to install (e.g. from `f-droid.org`).

OPTIONS:
        [ -h ]  Print usage

OUTPUT:
        N/A

DESCRIPTION:

A script for uninstalling apps on an android device via adb shell (and
disallowing automatic reactivation). The script removes a list of
pre-installed apps from Google, Huawei, Facebook, and other junk without
breaking the system. Additionally, basic apps like contacts, dialer,
keyboard, filemanger, gallery, browser, notes, etc. are replaced by
open-source ones (`simplemobiletools` available on F-Droid). Change
these if you prefer other apps (or update their versions/URLs).

J.A., xrzfyvqk_k1jw@pm.me
'

trap 'echo error on line: $LINENO' ERR

print_usage() {
    echo -e "android_cleanup:  uninstall extraneous apps and/or replace with open-source ones.
    Usage: ./${0##*/}
    [ -h ]              Print usage and exit\n"
}

while getopts 'h' option; do
    case $option in
        h) print_usage;  exit 0 ;;
        *) echo -e 'Incorrect usage! See below:\n'; 
           print_usage;  exit 1 ;;
    esac
done

cat > package_urls.txt << EOF
https://f-droid.org/repo/rkr.simplekeyboard.inputmethod_84.apk
https://f-droid.org/repo/com.simplemobiletools.filemanager.pro_103.apk
https://f-droid.org/repo/com.simplemobiletools.notes.pro_82.apk
https://f-droid.org/repo/com.simplemobiletools.musicplayer_86.apk
https://f-droid.org/repo/com.simplemobiletools.dialer_23.apk
https://f-droid.org/repo/com.simplemobiletools.flashlight_47.apk
https://f-droid.org/repo/com.simplemobiletools.contacts.pro_82.apk
https://f-droid.org/repo/com.simplemobiletools.gallery.pro_341.apk
https://dist.torproject.org/torbrowser/10.5.3/tor-browser-10.5.3-android-armv7-multi.apk
EOF

sed 's/.*\///g' package_urls.txt > packages_to_add.txt
wget -P /tmp/app_downloads -i package_urls.txt

for i in $(cat packages_to_add.txt); do
    echo installing package "$i ..."
    adb install /tmp/app_downloads/"$i"
done

for i in $(cat ./packages_to_remove.txt); do
    echo "uninstalling package $i ..."
    adb shell pm uninstall --user 0 "$i"
done

rm packages_to_add.txt package_urls.txt
rm -rf /tmp/app_downloads/

echo 'Done cleaning.'
