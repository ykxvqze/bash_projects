## Network scanner

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/netscan.sh">netscan.sh</a>: A reliable method for discovering other devices connected to your network. The script is based on `nmap` and `arp-scan`. IP and MAC addresses are extracted and summarized in tabular format. The system's local ARP cache is also used to fill in missing MAC addresses that correspond to IP addresses which may have been detected by nmap but not by arp-scan.

> Address Resolution Protocol (ARP) is a protocol for requesting information about an IP address; the response will be the MAC address of the network interface that has the requested IP address. An example is when a device must discover the MAC address of the gateway (router). ARP allows mapping an IP address to the link layer (MAC) address.

## Set up s-nail (send/receive mail via CLI)

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/snail_setup.sh">snail_setup.sh</a>: Bash script for installing and configuring s-nail. The script allows interactively adding/removing IMAP/SMTP configurations for mail accounts. Mail can then be fetched and sent (in ASCII format) via CLI with `s-nail` as demonstrated in the script. MIME attachments can be copied to separate files and then decoded (base64 decoding) before being viewed with an appropriate application depending on file type.

## One-time pad encryption

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/otp_crypt.sh">otp_crypt.sh</a>: Implementation of a one-time pad encryption/decryption method: includes utility functions and a demo.
<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/crypt_info.md">crypt_info.md</a>: A summary on public-key encryption and OTP symmetric-key encryption.

## Delete metadata

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/del_metadata.sh">del_metadata.sh</a>: Bash script for deleting metadata (author name; date timestamps) from a docx (Word) document. Metadata in the output file will appear empty (no author), (no date), including comments in the margin which will now appear with no author and no timestamps.

<!--a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/del_metadata.py">del_metadata.py</a>: Python script that does the same as above, however with an additional (mask) option for modifying timestamps of comments using numpy. If the mask option is specified, then timestamps of comments in the margin will be changed through randomization where timestamps are assigned with an incremental component drawn from a uniform distribution.
-->
## Scrape image files from xkcd site

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/scrape_xkcd.sh">scrape_xkcd.sh</a>: scrape cartoon images from an (inaccessible) xkcd directory. The script keeps a log of the last page scraped (from its previous execution if any) and will start fetching images from where it left off (i.e. adding only new cartoon images to a designated directory).

## Linecutter tool

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/linecutter.sh">linecutter.sh</a>: Insert line breaks in a text file at a limit of 72 characters but without breaking the last word.

## Sysops utility functions

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/sysutil.sh">sysutil.sh</a>: Utility functions set up for daily sysops. The script should be sourced (note: it is a growing script; more functions will be written and added with time ...).
```
. ./sysutil.sh                    # Source the script; internal functions include:
    |
    |--- battery_status           # Show battery percentage charge remaining;
    |--- userinfo                 # List users currently logged in, number of sessions, etc.;
    |--- ports_open               # List TCP ports open on localhost;
    |--- sysinfo                  # List user/superuser, OS info, RAM, local/global IP address;
    |--- config_files             # Check for existence of important configuration files;
    |--- log_rotate <file>        # Split file if > 100mB into smaller ones, gzip them and store;
    |--- mysql_backup [ -r ]      # Backup all mysql databases into ~/backup/mysql/ and optionally
                                  # use switch -r for sending the backup to remote server via rsync
                                  # (backups older than 1 week are automatically deleted);
```

## Security auditing/hardening

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/scansec.sh">scansec.sh</a>: interactive script for server security auditing and hardening. Note: option -a activates an audit-only mode (i.e. no hardening actions are executed). The main functions of `scansec.sh` (along with areas audited) are listed below.

```
scansec.sh
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

## Android cleanup

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/android_cleanup.sh">android_cleanup.sh</a>: script to brute-force uninstall and/or replace extraneous android apps (i.e. bloatware) with open source apps and disallowing automatic reactivation. The list of packages to uninstall can be modified prior script execution.

## Privacy-preserving method for merging datasets

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/database_merger.md">database_merger.md</a>: A proposed method for merging datasets that contain sensitive information from two different parties without revealing any identifying information to either party. The task can be accomplished via a third party, e.g. a bot, without the bot receiving any identifying information either.
