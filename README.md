# Mini Projects

## Set up s-nail (send/receive email via CLI)

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/snail_setup.sh">snail_setup.sh</a>: bash script for installing and configuring s-nail. The script allows interactively adding/removing IMAP/SMTP configurations for email accounts. Email can then be fetched and send (in ASCII format) via CLI with the s-nail command as shown in the script (under Examples). External CSS stylesheets, images (and web beacons), and other links can be viewed as plaintext and will not be fetched as when email is viewed via browser or web client.

## One-time pad encryption

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/otp_crypt">otp_crypt</a>: Implementation of a one-time pad encryption/decryption method: includes utility functions and a demo.
<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/crypt_info.md">crypt_info.md</a>: A summary on public-key encryption and OTP symmetric key-encryption.

## Delete metadata

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/del_metadata.sh">del_metadata.sh</a>: bash script for deleting metadata (author name; date timestamps) from a docx (Word) document. Metadata in the output file will appear empty (no author), (no date), including comments in the margin which will have no author and no timestamps. 

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/del_metadata.py">del_metadata.py</a>: python script that does the same as above, however with an additional (mask) option for modifying timestamps of comments using numpy. If the mask option is specified, then timestamps of comments in the margin will be changed through randomization where timestamps are assigned with an incremental component drawn from a uniform distribution.   

## Linecutter tool

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/linecutter">linecutter</a>: Insert line breaks in a text file at a limit of 72 characters without cutting words and without allowing a space character to start the next line (i.e. the space character is deleted).

## Scrape image files from xkcd site

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/scrape_imgs.sh">scrape_img.sh</a>: download cartoon images from an (inaccessible) xkcd directory.

## Random web traffic generator

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/traffic_gen.sh">traffic_gen.sh</a>: generates random web traffic (obfuscation).

## Android cleanup

<a class="external reference" href="https://github.com/thln2ejz/Scripting_Bash/blob/master/android_cleanup.sh">android_cleanup.sh</a>: android debloating script to uninstall and replace bloatware with open source apps.
