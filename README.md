## Set up s-nail (send/receive email via CLI)

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/snail_setup.sh">snail_setup.sh</a>: bash script for installing and configuring s-nail. The script allows interactively adding/removing IMAP/SMTP configurations for mail accounts. Mail can then be fetched and sent (in ASCII format) via CLI with the s-nail command as shown in the script (under 'Examples'). External CSS stylesheets, images (and web beacons), and other links can be viewed as plaintext and will not be fetched as when mail is viewed via browser or web client.

## One-time pad encryption

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/otp_crypt.sh">otp_crypt.sh</a>: Implementation of a one-time pad encryption/decryption method: includes utility functions and a demo.
<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/crypt_info.md">crypt_info.md</a>: A summary on public-key encryption and OTP symmetric key-encryption.

## Delete metadata

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/del_metadata.sh">del_metadata.sh</a>: bash script for deleting metadata (author name; date timestamps) from a docx (Word) document. Metadata in the output file will appear empty (no author), (no date), including comments in the margin which will have no author and no timestamps.

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/del_metadata.py">del_metadata.py</a>: python script that does the same as above, however with an additional (mask) option for modifying timestamps of comments using numpy. If the mask option is specified, then timestamps of comments in the margin will be changed through randomization where timestamps are assigned with an incremental component drawn from a uniform distribution.

## Linecutter tool

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/linecutter.sh">linecutter.sh</a>: Insert line breaks in a text file at a limit of 72 characters but without breaking the last word.

## Network scanner

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/netscan.sh">netscan.sh</a>: A reliable method for discovering other devices connected to the local area network. The script is based on nmap and arp-scan. IP and MAC addresses are extracted and summarized in table format. The system's local ARP* cache is also used to fill in missing MAC addresses that correspond to IP addresses which may have been detected by nmap but not by arp-scan.

*Address Resolution Protocol (ARP) is a protocol for requesting information about an IP address; the response will be the MAC address of
the device that has the requested IP address. Hence, ARP allows mapping an IP address to the link layer (MAC) address. ARP is also used when a device must discover the MAC address of the gateway (router) to be able to connect to the Internet for the first time.
<!--
## Scrape image files from xkcd site

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/scrape_imgs.sh">scrape_img.sh</a>: download cartoon images from an (inaccessible) xkcd directory.
-->

## Android cleanup

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/android_cleanup.sh">android_cleanup.sh</a>: android debloating script to uninstall and replace bloatware with open source apps.

## Privacy-preserving method for merging datasets

<a class="external reference" href="https://github.com/thln2ejz/bash_projects/blob/master/database_merger.md">database_merger.md</a>: A proposed method for merging datasets that contain sensitive information from two different parties without revealing any identifying information to either party. The task can be accomplished via a third party, e.g. a bot, without the bot receiving any identifying information either.
