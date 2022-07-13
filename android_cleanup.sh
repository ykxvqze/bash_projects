#!/usr/bin/env bash
: '
Uninstall and replace extraneous apps in Android with open-source ones.

USAGE:  ./android_cleanup.sh [ -h ]

                Phone must be connected by USB with debug mode enabled
                under `Developer` options. File packages_to_remove.txt
                should list apps to remove (1 per line) and can be
                modified as needed. Packages to install are listed in
                the file package_urls.txt and can be modified by
                removing or adding URLs of open source apps to install
                as replacement (e.g. from `f-droid.org`).

OPTIONS:
        [ -h ]  Print usage

OUTPUT:
        N/A

DESCRIPTION:

A script for uninstalling apps on an Android device via adb shell (
disallowing automatic reactivation). The script removes a list of
preinstalled apps from Google, Huawei, Facebook, etc. without breaking
the system. Additionally, basic apps like contacts, dialer, keyboard,
filemanger, gallery, browser, notes, etc. are replaced by open-source
ones (`simplemobiletools` available on F-Droid); change these if you
prefer other apps or update current versions in the URLs file.

J.A., xrzfyvqk_k1jw@pm.me
'

trap 'echo error on line: $LINENO' ERR

if [ -z `which adb` ]; then
    echo 'adb is not installed. Installing...'
    sudo apt-get install adb
fi

print_usage() {
    echo -e "android_cleanup:  uninstall and replace extraneous apps with open-source ones.
    Usage:
    ./${0##*/}             Install packages from package_urls.txt and uninstall those listed in packages_to_remove.txt
    ./${0##*/} [ -h ]      Print usage and exit\n"
}

while getopts 'h' option; do
    case $option in
        h) print_usage;  exit 0 ;;
        *) echo -e 'Incorrect usage!\n';
           print_usage;  exit 1 ;;
    esac
done

wget -P /tmp/app_downloads -i ./package_urls.txt
sed 's/.*\///g' package_urls.txt > /tmp/packages_to_add.txt

# add packages in same order listed in ./package_urls.txt
for i in $(cat /tmp/packages_to_add.txt); do
    echo installing package "$i ..."
    adb install /tmp/app_downloads/"$i"
done

for i in $(cat ./packages_to_remove.txt); do
    echo "uninstalling package $i ..."
    adb shell pm uninstall --user 0 "$i"
done

rm -rf /tmp/packages_to_add.txt
rm -rf /tmp/app_downloads/

echo 'Done cleaning.'
