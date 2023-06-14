## Network scanner

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/netscan.sh">netscan.sh</a>: A method for discovering devices connected to a network. The script is based on _nmap_ and _arp-scan_. IP and MAC addresses are extracted and summarized in tabular format.

## IPv4 networking

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/iptx.sh">iptx.sh</a>: utility functions for transforming IPv4 addresses from decimal-dotted notation into binary and vice versa, as well as for transforming CIDR notation into a network address, broadcast address, netmask, etc. <br>

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/ipv4.md">ipv4.md</a>: short summary on IPv4 addresses. 

## Set up s-nail (send/receive mail via CLI)

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/snail.sh">snail.sh</a>: script for installing and configuring s-nail. The script allows interactively adding/removing IMAP/SMTP configurations for mail accounts. Mail can then be fetched and sent in ASCII format via CLI.

## Sysops utility functions

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/sysutil.sh">sysutil.sh</a>: Utility functions for daily sysops.
<!--```
. ./sysutil.sh                    # Source the script; internal functions include:
    |
    |--- battery_status           # Show battery percentage charge remaining;
    |--- userinfo                 # List users currently logged in, number of sessions, etc.;
    |--- ports_open               # List TCP ports open on localhost;
    |--- sysinfo                  # List user/superuser, OS info, RAM, WAN/LAN/gateway IP addresses
    |--- geodata                  # List country, city, and geo-coordinates based on IP address
    |--- getmac <iface>           # Get MAC address of network interface <iface>
    |--- config_files             # Check for existence of important configuration files;
    |--- log_rotate <file>        # Split file if > 100mB into smaller ones, gzip them and store;
    |--- mysql_backup [ -r ]      # Backup all mysql databases into ~/backup/mysql/ and optionally
    |                             # use switch -r for sending the backup to remote server via rsync
    |                             # (backups older than 1 week are automatically deleted);
    |--- debugmode [ -s | -u ]    # Set an informative PS4 prompt and enable xtrace mode via -s;
                                  # reset PS4 to default prompt (+) and disable xtrace mode via -u
```
-->

## Security auditing/hardening

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/auditscan.sh">auditscan.sh</a>: interactive script for server security auditing and hardening.

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/scansec/scansec.sh">scansec.sh</a>: script that runs a set of test files containing audit rules that can be independently expanded to include more rules. In this design, the rules are not hard-coded into the script itself - which only handles the display and report.
<!--
```
auditscan.sh
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
```
-->

## SSH ban

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/sshban.sh">sshban.sh</a>: script for processing _/var/log/auth.log_, alerting via mail, and automatically logging and banning IP addresses that have multiple failed SSH login attempts.

## Apache2 setup

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/apache2.sh">apache2.sh</a>: script for installing Apache2 httpd server and setting up a password-protected virtual host via .htaccess and .htpasswd files.

## One-time pad encryption

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/otpcrypt.sh">otpcrypt.sh</a>: Implementation of a one-time pad encryption/decryption method: includes utility functions and a demo. <br>
<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/cryptinfo.md">cryptinfo.md</a>: A summary on public-key encryption and OTP symmetric-key encryption.

## Delete metadata

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/delmeta.sh">delmeta.sh</a>: Bash script for deleting metadata (author name; date timestamps) from a docx document. Metadata in the output file will appear empty, including comments in the margin.

<!--a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/delmeta.py">delmeta.py</a>: Python script that does the same as above, however with an additional (mask) option for modifying timestamps of comments using numpy. If the mask option is specified, then timestamps of comments in the margin will be changed through randomization where timestamps are assigned with an incremental component drawn from a uniform distribution.
-->
## Scrape image files from xkcd site

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/scrapexkcd.sh">scrapexkcd.sh</a>: scrape cartoon images from an inaccessible xkcd directory. The script keeps a log of the last page scraped from any previous execution and will start fetching images from where it left off (i.e. adding only new images to a designated directory).

## Linecutter tool

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/linecutter.sh">linecutter.sh</a>: Insert line breaks in a text file at a limit of 72 characters but without breaking any word.

## Android cleanup

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/android_cleanup.sh">android_cleanup.sh</a>: script to brute-force uninstalling extraneous android apps (disallowing automatic reactivation) and replacing preinstalled ones with open source apps. The list of packages to install/uninstall can be modified prior script execution.

## CLI plot

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/cliplot.sh">cliplot.sh</a>: tool for plotting a numeric sequence within the CLI without needing an X window system to view the plot. The plot is 'painted' top-level down in the CLI, line-by-line. This tool is useful for quick assessment of values such as CPU or memory usage over time (see 'Examples' in script).

```bash
$ ./cliplot.sh 1 4 9 16 25 36 49 64 81 100

    |                   |
    |                 | |
    |               | | |
 y  |               | | |
    |             | | | |
    |           | | | | |
    |       | | | | | | |
    | | | | | | | | | | |
     --------------------
      1                 10

Count   : 10
Minimum : 1
Maximum : 100
```

<!--## Subsetting Dataframes

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/subset">subset</a>: tool for transposing or slicing a dataframe given in a CSV file. Subsetting can be done via row(s) and/or column(s). It also supports an option for dropping rows and/or columns.

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/shape">shape</a>: finds the dimensions of a dataframe given in a CSV file.
-->
