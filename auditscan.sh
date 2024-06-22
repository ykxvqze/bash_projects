#!/usr/bin/env bash
: '
An interactive script for server security auditing/hardening.

USAGE: ./auditscan.sh [ -h | -a ]

OPTIONS:
        [ -h ]    Print usage and exit
        [ -a ]    Activate audit-only mode (no hardening/actions)"

OUTPUT:
         The script will permit selecting all or specific categories of
         system and network configuration files to audit; it also allows
         applying security hardening via interactive (y/n) responses unless
         flag -a is set (activating audit-only mode).

DESCRIPTION:

auditscan.sh will check for several commonly weak configuration settings
relating to system files and networks. These audits include the default
umask, login settings, password/group/shadow files, disabling services
such as CUPS and rpcbind, and disabling IPv4 forwarding. The internal
functions (along with areas audited) are listed below.

auditscan
|--- check_umask()
|    |--- default umask for users = 077
|    |--- default umask for root = 077
|--- check_login_settings()
|    |--- Maximum number of days till password change = 90
|    |--- Number of days till account locking for user inactivity = 30
|    |--- Lockout time upon 5 unsuccessful login attempts = 10 minutes
|    |--- Delay time between separate logins  = 10 seconds
|    |--- Disallow non-local logins to privileged accounts = ON
|--- check_sysfiles()
|    |--- check user/group ownership and permissions for /etc/passwd and /etc/passwd-
|    |--- check user/group ownership and permissions for /etc/shadow and /etc/shadow-
|    |--- check user/group ownership and permissions for /etc/group and /etc/group-
|    |--- check user/group ownership and permissions for /etc/gshadow and /etc/gshadow-
|    |--- check user/group ownership and permissions for /etc/security/opasswd
|--- check_services()
|    |--- CUPS print server
|    |--- rpcbind (NFS)
|----check_sshd()
|    |--- Port 22 (change to another port; security by obscurity)
|    |--- LogLevel INFO
|    |--- IgnoreRhosts yes
|    |--- HostbasedAuthentication no
|    |--- PermitRootLogin no
|    |--- PermitEmptyPasswords no
|    |--- PermitUserEnvironment no
|    |--- #X11Forwarding yes (i.e. disable it)
|--- check_networks()
     |--- Ipv4 forwarding = disabled

EXAMPLES:

./auditscan
./auditscan -a
'

print_usage(){
    echo -e "auditscan.sh: security auditing/hardening
    Usage: ./${0##*/}
    [ -h ]            Print usage and exit
    [ -a ]            Activate audit-only mode (no hardening/actions)\n"
}

define_colors(){
    default='\e[0m'
    red='\e[31m'
    green='\e[32m'
    orange='\e[33m'
    blue='\e[34m'
}

check_umask(){
	<<- 'EOF'
	umask shows bits (in octal form) that are NOT set upon creation of files or directories, e.g.
	umask 022 indicates no 'w' for group-owner and others (since 2=010). These disallowed bits are
	to be added to the already disallowed bits upon file or directory creation: default file
	permissions are 666 (rw-rw-rw-), whereas for directories 777. Result for files would be (rw-r--r--)
	EOF

    define_colors

    # audit
    echo ''
    echo -e "${blue}-----------------------[checking umask]-----------------------"

    val=`grep '^UMASK' /etc/login.defs | grep -oE '[0-9]+'`
    if [ ${val} -eq '077' ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of default umask for users is ${val} ${status}"
    echo -e "    File : /etc/login.defs"
    echo -e "    Value: `grep '^UMASK' /etc/login.defs`"

    # hardening
    if [ ! "$audit_only" -a ${val} -ne '077' ]; then
        echo -e "${orange}[?] Set default umask for users to: 077 (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE 's/(^UMASK\s+)[0-9]+/\1077/' /etc/login.defs | grep '^UMASK'
            echo 'OK'
        fi
    fi

    val=`sudo grep '^# umask' /root/.bashrc | grep -oE '[0-9]+'`
    if [ ${val} -eq '077' ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of default umask for root is ${val} ${status}"
    echo -e "    File : /root/.bashrc"
    echo -e "    Value: `sudo grep '^# umask' /root/.bashrc`"

    if [ ! "$audit_only" -a ${val} != '077' ]; then
        echo -e "${orange}[?] Set default umask for root to: 077 (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sudo sed -iE '/^# umask\s+[0-9]+/a\umask 077' /root/.bashrc | grep '^umask'
            echo 'OK'
        fi
    fi

    echo -e "$default"
}

check_login_settings(){
	<<- 'EOF'
	Check for the below:
	* Maximum number of days till password change = 90.
	* Number of days till account locking for user inactivity = 30.
	* Lockout time upon 5 unsuccessful login attempts = 10 minutes.
	* Delay time between separate logins  = 10 seconds.
	* Disallow non-local logins to privileged accounts = ON
	EOF

    define_colors
    echo ''
    echo -e "${blue}-----------------------[checking login settings]-----------------------"

    val=`grep '^PASS_MAX_DAYS' /etc/login.defs | grep -oE '[0-9]+'`
    if [ $val -eq '90' ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of maximum number of days for password setting is ${val} ${status}"
    echo -e "    File : /etc/login.defs"
    echo -e "    Value: `grep '^PASS_MAX_DAYS' /etc/login.defs`"

    # hardening
    if [ ! "$audit_only" -a ${val} -ne '90' ]; then
        echo -e "${orange}[?] Set maximum number of days till password change to: 90 (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE 's/(^PASS_MAX_DAYS\s+)[0-9]+/\190/' /etc/login.defs | grep -E 'PASS_MAX_DAYS\s+[0-9]+'
            echo 'OK'
        fi
    fi

    val=`sudo useradd -D  |
         grep '^INACTIVE' |
         sed 's/.*=//'`
    if [ $val -eq '30' ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of number of days till account locking for user inactivity is ${val} ${status}"
    echo -e "    Command: sudo useradd -D | grep '^INACTIVE'"
    echo -e "    Value  : `sudo useradd -D | grep '^INACTIVE'`"

    # hardening
    if [ ! "$audit_only" -a ${val} -ne '30' ]; then
        echo -e "${orange}[?] Set number of days till account locking for user inactivity to: 30 (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sudo useradd -D -f 30
            echo "sudo useradd -D -f 30"
            echo 'OK'
        fi
    fi

    val=`grep -E '.*auth required pam_tally2\.so onerr=fail audit silent deny=5 unlock_time=600.*' /etc/pam.d/login &> /dev/null
         echo $?`
    if [ $val -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of lockout time upon 5 unsuccessful login attempts ${status}"
    echo -e "    File : /etc/pam.d/login"
    echo -e "    Value: `grep -E '.*auth required pam_tally2\.so onerr=fail audit silent deny=5 unlock_time=600.*' /etc/pam.d/login || echo N/A`" 

    # hardening
    if [ ! "$audit_only" -a ${val} -ne '0' ]; then
        echo -e "${orange}[?] Set lockout time upon 5 unsuccessful login attempts to: 10 minutes (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/session\s+optional\s+pam_keyinit.so\s+force\s+revoke/a\auth required pam_tally2\.so onerr=fail audit silent deny=5 unlock_time=600' /etc/pam.d/login | grep 'unlock_time='
            echo 'OK'
        fi
    fi

    val=`grep -E '.*delay=.*' /etc/pam.d/login | grep -oE '[0-9]+'`
    if [ $val -eq 10000000 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of delay time between separate logins is ${val} microseconds ${status}"
    echo -e "    File : /etc/pam.d/login"
    echo -e "    Value: `grep -E '.*delay=.*' /etc/pam.d/login`"

    # hardening
    if [ ! "$audit_only" -a ${val} -ne '10000000' ]; then
        echo -e "${orange}[?] Set delay time between separate logins to: 10 seconds (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE "s/(delay=)[0-9]+/\110000000/" /etc/pam.d/login | grep 'delay='
            echo 'OK'
        fi
    fi

    val=`grep -E '^-:wheel:ALL EXCEPT LOCAL.*' /etc/security/access.conf &> /dev/null
         echo $?`
    if [ $val -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of disallowing non-local logins to privileged accounts ${status}"
    echo -e "    File : /etc/security/access.conf"
    echo -e "    Value: `grep -E '^#-:wheel:ALL EXCEPT LOCAL.*' /etc/security/access.conf || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a ${val} -ne 0 ]; then
        echo -e "${orange}[?] Set a disallow on non-local logins to privileged accounts (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/^#-:wheel:ALL EXCEPT LOCAL.*/s/#//' /etc/security/access.conf | grep '.*EXCEPT LOCAL'
            echo 'OK'
        fi
    fi

    echo -e "$default"
}

check_file(){
	<<- 'EOF'
	Check user/group ownership and permissions for a single file.
	USAGE:   check_file <user> <group> <permissions> <file>
	EXAMPLE: check_file root root 644 /etc/passwd
	EOF

    user="$1"
    group="$2"
    permissions="$3"
    file="$4"

    user_owner=`stat -c '%U' ${file}`
    group_owner=`stat -c '%G' ${file}`
    access=`stat -c '%a' ${file}`
    echo -e "${blue}${file}:"
    if [ $user_owner == ${user} ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of user-ownership of file ${file} is ${user_owner} ${status}"

    if [ $group_owner == ${group} ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of group-ownership of file ${file} is ${group_owner} ${status}"

    if [ $access == ${permissions} ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of file permissions of ${file} is ${access} ${status}"

    # hardening
    if [ ! "$audit_only" -a ${user_owner} != ${user} ]; then
        echo -e "${orange}[?] Set ${user} as user-owner of file ${file} (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sudo chown ${user}:${group} ${file}
            echo "sudo chown ${user}:${group} ${file}"
            echo 'OK'
        fi
    fi

    if [ ! "$audit_only" -a ${group_owner} != ${group} ]; then
        echo -e "${orange}[?] Set ${group} as group-owner of file ${file} (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sudo chown ${user}:${group} ${file}
            echo "sudo chown ${user}:${group} ${file}"
            echo 'OK'
        fi
    fi

    if [ ! "$audit_only" -a ${access} != ${permissions} ]; then
        echo -e "${orange}[?] Set file permissions of ${file} to: ${permissions} (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sudo chmod ${permissions} ${file}
            echo "sudo chmod ${permissions} ${file}"
            echo 'OK'
        fi
    fi

    echo -e "$default"
}

check_sysfiles(){
	<<- 'EOF'
	Check user/group ownership and permissions of system files:
	* /etc/passwd and /etc/passwd-
	* /etc/shadow and /etc/shadow-
	* /etc/group and /etc/group-
	* /etc/gshadow and /etc/gshadow-
	* /etc/security/opasswd
	EOF

    define_colors
    echo ''
    echo -e "${blue}-----------------------[checking system files]-----------------------"

    # /etc/passwd
    check_file root root 644 /etc/passwd

    # /etc/shadow
    check_file root shadow 640 /etc/shadow

    # /etc/group
    check_file root root 644 /etc/group

    # /etc/gshadow
    check_file root shadow 640 /etc/gshadow

    # /etc/passwd-
    check_file root root 600 /etc/passwd-

    # /etc/shadow-
    check_file root root 600 /etc/shadow-

    # /etc/group-
    check_file root root 600 /etc/group-

    # /etc/gshadow-
    check_file root shadow 600 /etc/gshadow-

    # /etc/security/opasswd
    check_file root root 600 /etc/security/opasswd

    echo -e "$default"
}

check_services(){
	<<- 'EOF'
	Check and kill any of the following services if active:
	* CUPS print server
	* rpcbind (NFS)
	EOF

    define_colors
    echo ''
    echo -e "${blue}-----------------------[checking active services]-----------------------"

    # CUPS
    is_active=`systemctl is-active cups`
    if [ $is_active == 'inactive' ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of CUPS service is ${is_active} ${status}"
    echo -e "    Command: systemctl is-active cups"
    echo -e "    Value  : ${is_active}"

    # hardening
    if [ ! "$audit_only" -a ${is_active} == 'active' ]; then
        echo -e "${orange}[?] Disable CUPS service (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            systemctl disable cups
            echo 'systemctl disable cups'
            echo 'OK'
        fi
    fi

    # rpcbind (NFS)
    is_active=`systemctl is-active rpcbind`
    if [ $is_active == 'inactive' ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of rpcbind service is ${is_active} ${status}"
    echo -e "    Command: systemctl is-active rpcbind"
    echo -e "    Value  : ${is_active}"

    # hardening
    if [ ! "$audit_only" -a ${is_active} == 'active' ]; then
        echo -e "${orange}[?] Disable rpcbind service (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            systemctl disable rpcbind
            echo 'systemctl disable rpcbind'
            echo 'OK'
        fi
    fi

    echo -e "$default"
}

check_sshd(){
	<<- 'EOF'
	Check that the following SSH configurations are set:
	* Port 22 (change to another port; security by obscurity)
	* LogLevel INFO
	* IgnoreRhosts yes
	* HostbasedAuthentication no
	* PermitRootLogin no
	* PermitEmptyPasswords no
	* PermitUserEnvironment no
	* #X11Forwarding yes (i.e. disable it)
	EOF

    define_colors
    echo ''
    echo -e "${blue}-----------------------[checking sshd configurations]-----------------------"

    if [ ! -f /etc/ssh/sshd_config ]; then
        echo -e "\nFile /etc/ssh/sshd_config does not exist.\nCheck that SSH server is installed!${default}\n"
        return 1
    fi

    check_file root root 600 /etc/ssh/sshd_config

    # port 22 changed?
    is_port_default=`grep '^#Port 22' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_port_default -ne 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH port ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^#Port 22' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_port_default -eq 0 ]; then
        echo -e "${orange}[?] Change SSH port from default (22) to 57381 (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE 's/^#Port 22/Port 57381/' /etc/ssh/sshd_config | grep 'Port 57381'
            echo 'OK'
        fi
    fi

    # Set SSH LogLevel to INFO
    is_loglevel_info=`grep '^LogLevel INFO' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_loglevel_info -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH LogLevel set of INFO ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^LogLevel' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_loglevel_info -ne 0 ]; then
        echo -e "${orange}[?] Set SSH LogLevel to INFO (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/LogLevel INFO/s/^#//' /etc/ssh/sshd_config | grep 'LogLevel INFO'
            echo 'OK'
        fi
    fi

    # SSH IgnoreRhosts
    is_ignore_rhosts=`grep '^IgnoreRhosts yes' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_ignore_rhosts -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH IgnoreRhosts ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^IgnoreRhosts' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_ignore_rhosts -ne 0 ]; then
        echo -e "${orange}[?] Enable IgnoreRhosts (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/IgnoreRhosts.*/s/^#//' /etc/ssh/sshd_config | grep 'IgnoreRhosts'
            echo 'OK'
        fi
    fi

    # SSH HostbasedAuthentication
    is_hostauth_off=`grep '^HostbasedAuthentication no' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_hostauth_off -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH HostbasedAuthentication ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^HostbasedAuthentication' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_hostauth_off -ne 0 ]; then
        echo -e "${orange}[?] Disable HostbasedAuthentication (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/HostbasedAuthentication.*no/s/^#//' /etc/ssh/sshd_config | grep 'HostbasedAuthentication no'
            echo 'OK'
        fi
    fi

    # SSH PermitRootLogin
    is_rootlogin_off=`grep '^PermitRootLogin no' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_rootlogin_off -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH PermitRootLogin ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^PermitRootLogin' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_rootlogin_off -ne 0 ]; then
        echo -e "${orange}[?] Disable PermitRootLogin (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE 's/#PermitRootLogin\s+prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config | grep 'PermitRootLogin no'
            echo 'OK'
        fi
    fi

    # SSH PermitEmptyPasswords
    is_emptypasswd_off=`grep '^PermitEmptyPasswords no' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_emptypasswd_off -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH PermitEmptyPasswords ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^PermitEmptyPasswords' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_emptypasswd_off -ne 0 ]; then
        echo -e "${orange}[?] Disable PermitEmptyPasswords (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/PermitEmptyPasswords.*no/s/^#//' /etc/ssh/sshd_config | grep 'PermitEmptyPasswords no'
            echo 'OK'
        fi
    fi

    # SSH PermitUserEnvironment
    is_userenv_off=`grep '^PermitUserEnvironment no' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_userenv_off -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH PermitUserEnvironment ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^PermitUserEnvironment' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_userenv_off -ne 0 ]; then
        echo -e "${orange}[?] Disable PermitUserEnvironment (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE '/PermitUserEnvironment.*no/s/^#//' /etc/ssh/sshd_config | grep 'PermitUserEnvironment no'
            echo 'OK'
        fi
    fi

    # SSH X11Forwarding
    is_x11_off=`grep '^#X11Forwarding yes' /etc/ssh/sshd_config &> /dev/null; echo $?`
    if [ $is_x11_off -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of SSH X11Forwarding ${status}"
    echo -e "    File : /etc/ssh/sshd_config"
    echo -e "    Value: `grep '^#X11Forwarding yes' /etc/ssh/sshd_config || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_x11_off -ne 0 ]; then
        echo -e "${orange}[?] Disable X11Forwarding (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE 's/X11Forwarding.*yes/#X11Forwarding yes/' /etc/ssh/sshd_config | grep 'X11Forwarding yes'
            echo 'OK'
        fi
    fi

    echo -e "${blue}[*] Restarting sshd daemon (y/n)..."; read -s -n 1 x
    if [ ${x,,} == y ]; then
        sudo service sshd restart
        echo 'sudo service sshd restart'
        echo 'OK'
    fi

    echo -e "$default"
}

check_networks(){
    <<- 'EOF'
	Check that the following networking configurations are set:
	* IPv4 forwarding disabled
	* ...
	EOF

    define_colors
    echo ''
    echo -e "${blue}-----------------------[checking network configurations]-----------------------"

    # IPv4 forwarding
    is_ip_forward=`grep -E '^net\.ipv4\.ip_forward=0' /etc/sysctl.conf &> /dev/null; echo $?`
    if [ $is_ip_forward -eq 0 ]; then
        status="${green}[   OK   ]"
    else
        status="${red}[ NOT OK ]"
    fi
    echo -e "${default}[*] Status of IPv4 forwarding ${status}"
    echo -e "    File : /etc/sysctl.conf"
    echo -e "    Value: `grep -E '^#net\.ipv4\.ip_forward=0' /etc/sysctl.conf || echo N/A`"

    # hardening
    if [ ! "$audit_only" -a $is_ip_forward -ne 0 ]; then
        echo -e "${orange}[?] Disable IPv4 forwarding (y/n)"; read -s -n 1 x
        if [ ${x,,} == y ]; then
            sed -iE 's/^#net\.ipv4\.ip_forward=1/net.ipv4.ip_forward=0/' /etc/sysctl.conf | grep 'ip_forward'
            #sysctl -w net.ipv4.ip_forward=0
            echo 'OK'
        fi
    fi

    echo -e "$default"
}

main() {
    case "$1" in
        -a) audit_only=0                      ;;
        -h) print_usage              ; exit 0 ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
    esac

    echo -e 'select a category for security auditing/hardening:\n'
    select x in 'umask' 'login settings' 'config files' 'services' 'sshd' 'networks' 'all'; do
        echo "$x"
        break
    done

    case "$x" in
        'umask'         ) check_umask          ;;
        'login settings') check_login_settings ;;
        'config files'  ) check_sysfiles       ;;
        'services'      ) check_services       ;;
        'sshd'          ) check_sshd           ;;
        'networks'      ) check_networks       ;;
        'all'           ) check_umask; check_login_settings; check_sysfiles;
                          check_services; check_sshd; check_networks ;;
    esac
}

main "$@"
