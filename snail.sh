#!/usr/bin/env bash
: '
Set up s-nail for sending/receiving mail over SMTP/IMAP via CLI.

USAGE: ./snail.sh [-h] | [-s] | [-l] | [-a <account>] | [-r <account(s)>]

OPTIONS:
        [ -h ]               Print usage and exit
        [ -s ]               Show status on whether s-nail is installed and number of accounts registered
        [ -l ]               List all accounts registered in ~/.mailrc
        [ -a <account> ]     Add the specified account
        [ -r <account(s)> ]  Remove specified account(s)\n"

OUTPUT:
         s-nail will be installed if not already present. Options to add
         or remove accounts will request account info from the user
         interactively. File ~/.mailrc will be created and configured
         accordingly. Location for storing saved mail is set to a
         directory called `mailbox` under the home directory ($HOME/mailbox).

DESCRIPTION:

s-nail will be installed unless already present (Debian-based OS is
assumed). Email accounts can be added or removed via options -a and -r
respectively, and ~/.mailrc will be consequently created and configured
automatically.

EXAMPLES:

Once the script is done with installation and SMTP/IMAP configurations:

# view inbox (will be prompted to enter password)
s-nail -A gmail -L :u   # list unread messages (-A option for specifying account)
s-nail -A gmail -L u    # list all inbox messages for user

# send an email via SMTP
cat << EOF > reply
Hello,
I am sending an email.
Regards,
EOF

cat reply | s-nail -A outlook
                   -s "subject_line"
                   -a file1.zip
                   -c recipient1@outlook.com,recipient2@gmail.com
                   -b recipient3@pm.me
                   main_recipient@gmail.com

Option -s is for adding a subject line, -a for attachments,
-c for CC recipients, -b for BCC recipients.
Note: option -r "fake_address@somewhere.com" is often ignored by MTAs.

# Downloading/saving mail to view (as ASCII)

s-nail -A outlook        # run this in shell to get into interactive mode
> s 3 +mail_from_robin   # save 3rd email as "mail_from_robin" (+ sign to avoid overwriting path_to_mailbox directory)
> list                   # list all commands available
> delete 1-5
> delete 7 9 10
> exit                   # exit session

Note: mail will be in plaintext (ASCII); attachments and inline images
included in the mail may appear as base64-encoded. You can copy the encoded
text to a separate file (e.g. file1) and decode it like this:

base64 -d file1

For example, if the encoded text is an attachment of MIME-type application/pdf,
you can open it with a suitable application for viewing PDF (e.g. `evince`)
after decoding:

base64 -d file1 > file1_decoded
evince file1_decoded

J.A., ykxvqz@pm.me
'

path_to_mailbox="$HOME"/mailbox

print_usage() {
    echo -e "snail.sh: s-nail for sending/receiving mail over SMTP/IMAP via CLI.
    Usage: ./${0##*/}
    [ -h ]               Print usage and exit
    [ -l ]               List all accounts registered in ~/.mailrc
    [ -s ]               Show status on whether s-nail is installed and the number of accounts registered
    [ -a <account> ]     Add the specified account
    [ -r <account(s)> ]  Remove specified account(s)\n"
}

check_system_deb() {
    dpkg --version > /dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        echo 'System not supported. Exiting...'
        return 1
    else
        return 0
    fi
}

check_snail_installed() {
    check_system_deb
    if [ "$?" -eq 0 ]; then
        dpkg -l | grep 's-nail' | grep '^ii' &> /dev/null
        return "$?"
    else
        return 1
    fi
}

install_snail() {
    sudo apt-get install s-nail
}

check_mailrc_exists() {
    if [ -f ~/.mailrc ]; then
        return 0
    else
        echo 'file ~/.mailrc does not exist.'
        return 1
    fi
}

initialize_mailrc() {
    mkdir "$path_to_mailbox"
    touch ~/.mailrc
    chmod 700 ~/.mailrc

    cat > ~/.mailrc << EOF
set verbose
set folder="$path_to_mailbox"
EOF
}

check_account_exists() {
    grep "account $1\s" ~/.mailrc > /dev/null 2>&1
}

append_account() {
    echo 'This will store account information you supply in config file ~/.mailrc used by s-nail.'
    read -p 'Enter mail address (e.g. john.doe@gmail.com or john.doe@outlook.com): ' email_address
    read -p 'Enter mail password: ' -s email_password
    echo
    read -p 'Enter IMAP account (e.g. john.doe@imap.gmail.com or john.doe@imap-mail.outlook.com): ' imap_account
    read -p 'Enter SMTP address (e.g. smtp.gmail.com or smtp-mail.outlook.com): ' smtp_address
    echo 'Saving info in file ~/.mailrc'

    cat >> ~/.mailrc << EOF

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
}

remove_account() {
    check_system_deb || exit 1
    check_snail_installed || install_snail
    check_mailrc_exists || initialize_mailrc
    check_account_exists "$1"
    if [ "$?" -ne 0 ]; then
        echo "Account $1 does not exist."
    else
        line_numbers=`grep -n -A 10 "^account $1\s" ~/.mailrc |
                      tr ':-' '  '                            |
                      cut -d ' ' -f 1`
        start=`echo "$line_numbers" | head -1`
        end=`echo "$line_numbers" | tail -1`
        sed -i "${start},${end}d" ~/.mailrc
        echo "Account $1 removed."
    fi
}

add_account() {
    check_system_deb || exit 1
    check_snail_installed || install_snail
    check_mailrc_exists || initialize_mailrc
    check_account_exists "$1"
    if [ "$?" -eq 0 ]; then
        read -p 'Account already exists. Do you want to overwrite (y/n)? ' x
        case "$x" in
            n | N) echo 'Exiting...'; exit 1 ;;
            y | Y) remove_account "$1"; append_account "$1"; exit 0 ;;
            *    ) echo 'Invalid response. Exiting...'; exit 1 ;;
        esac
    else
        append_account "$1"
    fi
}

list_accounts() {
    if [ "$(grep 'account' ~/.mailrc | wc -l)" -ne 0 ]; then
        echo 'The accounts listed in ~/.mailrc are the following: '
        grep 'account' ~/.mailrc | cut -d ' ' -f 2
    else
        echo 'There are no accounts listed in ~/.mailrc'
    fi
}

status() {
    check_snail_installed && echo 's-nail is already installed.' || echo 's-nail is not installed.'
    check_mailrc_exists
    echo -n 'The number of accounts listed in ~/.mailrc is: '
    grep 'account' ~/.mailrc | wc -l
}

main() {
    case "$1" in
        -a) [ "$2" ] && add_account "$2" || { echo "$1 requires an argument"; exit 1; } ;;
        -r) if [ -n "$2" ]; then
                account_names="${@: 2:$#}"
                for i in $account_names; do
                    remove_account "$i"
                done
            fi ;;
        -s) status                   ; exit 0 ;;
        -l) list_accounts            ; exit 0 ;;
        -h) print_usage              ; exit 0 ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
         *) print_usage              ; exit 1 ;;
    esac
}

main "$@"
