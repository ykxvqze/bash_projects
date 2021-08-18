#!/usr/bin/env bash
: ' 
Set up s-nail for sending/receiving email over SMTP/IMAP via CLI.

Usage: ./snail_setup.sh [-h | --help] | [-a account_name] | [-r account_name(s)] | [ -s ] | [-l ]

OPTIONS:
         -h: show usage
         -a account_name: add an account
         -r account_name(s): remove specified account(s)
         -s: show status on whether s-nail is installed and number of accounts in ~/.mailrc 
         -l: list all account names present in ~/.mailrc

OUTPUT:
         s-nail will be installed if not already present. Options to add
         or remove accounts will requestion account info from user in the
         CLI. File ~/.mailrc will be created and configured accordingly.
         Location for storing saved emails when using s-nail is set to
         directory mailbox within home directory ($HOME/mailbox) via
         variable path_to_mailbox.

DESCRIPTION:

s-nail will be installed unless already present. The script assumes a
Debian-based OS and will exit with notification in case the system is
not. Email accounts can be added/removed via options -a and -r respectively,
and ~/.mailrc will be consequently created and configured automatically.

EXAMPLES:

Once the script is done with installation and SMTP/IMAP configuration:

# view inbox (will be prompted to enter password)
s-nail -A gmail -Lu    # list all inbox messages
s-nail -A gmail -L :u  # list unread inbox messages: 

# send an email via SMTP
cat > reply << EOF
Hello,
I am sending an email.
Regards,
EOF

cat reply | s-nail -A outlook -s subject_text -a file1.zip -c recipient1@outlook.com,recipient2@gmail.com -b recipient3@pm.me main_recipient@gmail.com

option -s is for adding a subject, -a for adding attachments, -c for CC recipients, -b for BCC recipients.
Note: option -r "fake_address@somewhere.com" is an often ignored option by MTUs.

# Downloading/saving an email to view (as ASCII)

s-nail -A outlool        #run this in shell to get into interactive mode
> s 3 +email_from_robin  #save 3rd email (i.e. with ID 3) as email_from_robin (+ sign to avoid overwriting the path_to_mailbox directory)
> list                   #list all commands within interactive mode
> delete 1-5
> delete 7 9 10
> exit                   # exit session

Note: the email will be in plain text (ASCII), i.e. no external images or
CSS stylesheets will be requested from external servers (only 1 HTTP request
is sent for fetching the email); attachments and inline images included
in the email may appear encoded (e.g. Content-Transfer-Encoding: base64).
You can copy encoded text to a separate file and decode it:

base64 -d [file]

If the encoded text is an attachment of type PDF, etc: 

base64 -d > file_decoded
evince file_decoded

J.A., xrzfyvqk_k1jw@pm.me
'

USAGE="Usage: ./snail_setup.sh [-h | --help] | [-a account] | [-r account] | [ -s ] | [-l ]"

path_to_mailbox=$HOME/mailbox
error_code=9

function get_system_info() {

    dpkg --version > /dev/null 2>&1
    system_is_deb=$?

    rpm --version > /dev/null 2>&1
    system_is_rpm=$?

    if [ $system_is_deb -ne 0 -a $system_is_rpm -ne 0 ]; then
        echo 'Your system is not supported, exiting ...'
        return error_code
    elif [ $system_is_deb -eq 0 -a $system_is_rpm -eq 0 ]; then
        system='deb'
    else
        if [ $system_is_rpm -eq 0 ]; then
            system='rpm'&
        else
            system='deb'
        fi
    fi
}


function check_snail_installed() {

    get_system_info

    if [ $system == 'deb' ]; then
        dpkg -l | grep s-nail &> /dev/null
        return $?
    else
        return error_code
    fi
}


function install_snail() {
    
    check_snail_installed

    if [ $? -eq 0 ]; then
        echo 's-nail is already installed.'
    elif [ $? -eq 1]; then
        echo 's-nail not found. Installing s-nail ...'
        sudo apt-get install s-nail
    else
        echo 'Your system is not supported, exiting ...'
        return error_code
    fi

}


function check_mailrc_exists() {

    [ -f ~/.mailrc ] && echo 'file ~./mailrc exists' || (echo 'file ~/.mailrc does not exist'; return 1)

}


function initialize_mailrc() {

    mkdir $path_to_mailbox
    touch ~/.mailrc
    chmod 700 ~/.mailrc

    cat > ~/.mailrc << EOF
set verbose
set folder=$path_to_mailbox
EOF

    echo "Outgoing mail directory created in $path_to_mailbox"

}


function check_account_exists() {

    grep "account $1\ " ~/.mailrc > /dev/null 2>&1

}


function append_account() {

    echo 'This will store account information you supply in configuration file ~/.mailrc used by s-nail.'
    read -p 'Enter email address (e.g. john.doe@gmail.com or john.doe@outlook.com): ' email_address
    read -p 'Enter email password: ' -s email_password
    echo 
    read -p 'Enter IMAP account (e.g. john.doe@imap.gmail.com or john.doe@imap-mail.outlook.com): ' imap_account
    read -p 'Enter SMTP address (e.g. smtp.gmail.com or smtp-mail.outlook.com): ' smtp_address
    echo 'Saving info in file ~/.mailrc'

    cat >> ~/.mailrc << EOF # change filename at end
account $1 {
    set inbox=imaps://$imap_account
    set imap-use-starttls
    set password-username@${imap_account#*@}=$email_password
    set smtp=smtp://$smtp_address
    set from=$email_address
    set smtp-use-starttls
    set smtp-auth="login"
    set smtp-auth-user=$email_address
    set smtp-auth-password=$email_password
    }
EOF

    echo 'Done!'
}


function remove_account() {

    check_account_exists "$1"

    if [ $? -ne 0 ]; then
        echo "Account $1 does not exist."
    else
        line_numbers=$(grep -n -A10 "^account $1\ " ~/.mailrc | tr ':-' ' ' | cut -d ' ' -f 1)
        start=$(echo $line_numbers | tr ' ' '\n' | sed -n '1,1p')
        end=$(echo $line_numbers | tr ' ' '\n' | sed -n '$,$p')
        sed -i "$start,${end}d" ~/.mailrc
        echo "Account $1 removed."
    fi
}


function add_account() {

    check_account_exists "$1"

    if [ $? -eq 0 ]; then
        read -p 'Account already exists. Do you want to overwrite (y/n)? ' x
        case $x in
            n | N) echo 'Exiting'; return 1;;
            y | Y) remove_account "$1"; append_account "$1";;
                *) echo 'Invalid response, exiting ...'; return 1;;
        esac
    else
        append_account "$1"
    fi
}


function list_accounts() {

    if [ $(grep 'account' ~/.mailrc | wc -l) -ne 0 ]; then
        echo 'The accounts listed in ~/.mailrc are the following: '
        echo
        grep 'account' ~/.mailrc | cut -d ' ' -f 2
    else
        echo 'There are no accounts listed in ~/.mailrc'
    fi
}


function status() {

    check_snail_installed && echo 's-nail is already installed' || echo 's-nail is not installed'

    check_mailrc_exists

    echo -n 'The number of accounts listed in ~/.mailrc is: '
    grep 'account' ~/.mailrc | wc -l

}


function main() {

    install_snail &> /dev/null || exit 1
    check_mailrc_exists &> /dev/null || initialize_mailrc

    case "$1" in
        -a | --add)
            [ "$2" ] && add_account "$2" || (echo "$1 requires an argument"; exit 1) ;;

        -r | --remove)
            [ "$2" ] && account_names="${@: 2:$#}" || (echo "$1 requires an argument"; exit 1)
            for i in $account_names; do
                remove_account $i
            done ;;

        -s | --status)
            [ "$2" ] && { echo "$1 takes no arguments"; exit 1; } || status ;;

        -l | --list)
            [ "$2" ] && { echo "$1 takes no arguments"; exit 1; } || list_accounts ;;

        -h | --help)
            echo "$USAGE"; exit 1 ;;

        -*) 
            echo "Unknown option: $1"; exit 1 ;;

        *)
            echo "Invalid arguments: $USAGE"; exit 1;;
    esac

}


main "$@"
