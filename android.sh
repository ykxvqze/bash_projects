#!/usr/bin/env bash

<< 'EOF'
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
EOF

__set_trap                 () { :; }
__print_usage              () { :; }
__parse_options            () { :; }
__check_adb_installed      () { :; }
__download_apps            () { :; }
__install_downloaded_apps  () { :; }
__uninstall_apps_to_remove () { :; }
__cleanup                  () { :; }
__main                     () { :; }

__set_trap() {
    trap 'echo error on line: $LINENO' ERR
}

__print_usage() {
    echo -e "Uninstall and replace extraneous apps with open-source ones.

    Usage:

        ./${0##*/}        Install packages from package_urls.txt and uninstall those listed in packages_to_remove.txt
        ./${0##*/} -h     Print usage and exit\n"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage;  exit 0 ;;
            *) echo -e 'Incorrect usage!\n';
               __print_usage;  exit 1 ;;
        esac
    done
}

__check_adb_installed() {
    if [ -z "$(which adb)" ]; then
        echo 'adb shell is not installed.'
        read -p 'Install adb shell (y/n)? ' -n 1 reply
        case "${reply,,}" in
            'y') echo -e '\nInstalling adb shell...';
                 sudo apt-get install adb ;;
            'n') echo -e '\nExiting...';
                 exit 0 ;;
            *  ) echo -e '\nInvalid response. Exiting...';
                 exit 1 ;;
        esac
    fi

    [ -z "$(which adb)" ] && { echo 'adb shell failed to install. Exiting...'; exit 1; }
}

__download_apps() {
    wget -P /tmp/app_downloads -i ./package_urls.txt
}

__install_downloaded_apps() {
    sed 's/.*\///g' package_urls.txt > /tmp/packages_to_add.txt

    # add packages in same order listed in ./package_urls.txt
    for i in $(cat /tmp/packages_to_add.txt); do
        echo "installing package $i ..."
        adb install /tmp/app_downloads/"$i"
    done
}

__uninstall_apps_to_remove() {
    for i in $(cat ./packages_to_remove.txt); do
        echo "uninstalling package $i ..."
        adb shell pm uninstall --user 0 "$i"
    done
}

__cleanup() {
    rm -rf /tmp/packages_to_add.txt
    rm -rf /tmp/app_downloads/

    echo 'Done cleaning.'
}

__main() {
    __set_trap
    __parse_options "$@"
    __check_adb_installed
    __download_apps
    __install_downloaded_apps
    __uninstall_apps_to_remove
    __cleanup
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    __main "$@"
fi
