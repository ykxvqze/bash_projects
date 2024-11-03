#!/usr/bin/env bash
: '
Uninstall and replace extraneous apps in Android with open-source ones.

USAGE:  ./android.sh  [ -h ]

                Phone must be connected by USB with Debug mode enabled
                under `Developer` options. File "packages_to_remove.txt"
                lists applications to remove (1-per-line). Packages to
                install are listed in the file "package_urls.txt" as
                URLs of open-source apps, e.g. from `f-droid.org`.

OPTIONS:
        [ -h ]  Print usage

OUTPUT:
        N/A

DESCRIPTION:

A script for uninstalling apps on an Android device via adb shell.
The script removes a list of preinstalled apps without breaking the
system. Additionally, basic apps like Contacts, Dialer, Keyboard,
File Manager, Gallery, Browser, Notes, etc. are replaced by open-source
ones (`simplemobiletools` available on F-Droid). These can be modified
in the file "package_urls.txt".
'

trap 'echo error on line: $LINENO' ERR

print_usage() {
    echo -e "android.sh:  uninstall and replace extraneous apps with open-source ones.
    Usage:
    ./${0##*/}        Install packages from package_urls.txt and uninstall those listed in packages_to_remove.txt
    ./${0##*/} -h     Print usage and exit\n"
}

while getopts 'h' option; do
    case "$option" in
        h) print_usage;  exit 0 ;;
        *) echo -e 'Incorrect usage!\n';
           print_usage;  exit 1 ;;
    esac
done

if [ -z "$(which adb)" ]; then
    echo 'adb shell is not installed.'
    read -p 'Install adb shell (y/n)? ' -n 1 x
    case "${x,,}" in
        'y') echo -e '\nInstalling adb shell...';
             sudo apt-get install adb ;;
        'n') echo -e '\nExiting...';
             exit 0 ;;
        *  ) echo -e '\nInvalid response. Exiting...';
             exit 1 ;;
    esac
fi

[ -z "$(which adb)" ] && { echo 'adb shell failed to install. Exiting...'; exit 1; }

wget -P /tmp/app_downloads -i ./package_urls.txt
sed 's/.*\///g' package_urls.txt > /tmp/packages_to_add.txt

# add packages in same order listed in ./package_urls.txt
for i in $(cat /tmp/packages_to_add.txt); do
    echo "installing package $i ..."
    adb install /tmp/app_downloads/"$i"
done

for i in $(cat ./packages_to_remove.txt); do
    echo "uninstalling package $i ..."
    adb shell pm uninstall --user 0 "$i"
done

rm -rf /tmp/packages_to_add.txt
rm -rf /tmp/app_downloads/

echo 'Done cleaning.'
