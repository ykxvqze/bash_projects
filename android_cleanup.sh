#!/usr/bin/env bash
: '
Android debloating script

Usage:  ./android_cleanup.sh
        
        Note: Phone should be connected by usb and debugging mode enabled under Developer options.
              ./packages_to_remove.txt file should list apps to remove (1 per line); modify as needed.

ARGS:
        None: N/A
        
Output:
        None: N/A

DESCRIPTION:

A script for debloating android Huawei device (nova 2 Plus) using adb shell;
Remove list of unnecessary preinstalled apps from Google, Huawei, Facebook, and other junk;
the list is in file packages_to_remove.txt and can be modified;  
Basic apps like contacts, dialer, filemanger, notes, musicplayer, etc. are replaced by 
open-source _simplemobiletools_ available on F-Droid. Change these if you prefer other apps.

J.A., xrzfyvqk_k1jw@pm.me
'

cat > package_urls.txt << EOF
https://f-droid.org/repo/rkr.simplekeyboard.inputmethod_84.apk
https://f-droid.org/repo/com.simplemobiletools.filemanager.pro_103.apk
https://f-droid.org/repo/com.simplemobiletools.notes.pro_82.apk
https://f-droid.org/repo/com.simplemobiletools.musicplayer_86.apk
https://f-droid.org/repo/com.simplemobiletools.dialer_23.apk
https://f-droid.org/repo/com.simplemobiletools.flashlight_47.apk
https://f-droid.org/repo/com.simplemobiletools.contacts.pro_82.apk
https://f-droid.org/repo/com.simplemobiletools.gallery.pro_341.apk
https://dist.torproject.org/torbrowser/10.5.3/tor-browser-10.5.3-android-armv7-multi.apk  # tor browser (firefox) for android
EOF

sed 's/.*\///g' package_urls.txt > packages_to_add.txt
wget -P /tmp/app_downloads -i package_urls.txt

for i in $(cat packages_to_add.txt); do
    echo installing package "$i" ...
    adb install /tmp/app_downloads/"$i"
done

for i in $(cat ./packages_to_remove.txt); do
    echo uninstalling package "$i" ...
    adb shell pm uninstall --user 0 "$i"
done

rm packages_to_add.txt package_urls.txt 
rm -r /tmp/app_downloads/

echo 'Done cleaning!'
