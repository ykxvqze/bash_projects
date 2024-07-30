#!/usr/bin/env bash
: '
Demo - install apache2 web server and set up a password-protected virtual host.

USAGE: sudo ./apache2.sh [ -h ]

OPTIONS:
      [ -h ]  Print usage

OUTPUT:
              Verify in browser: localhost/${virtual_host} (e.g. localhost/websiteA)

DESCRIPTION:

- Install apache2 server if not already installed.
- Set up a virtual host (e.g. by default: websiteA)
  - Create /var/www/html/"${virtual_host}"
  - Create /etc/apache2/sites-available/"${virtual_host}".conf and
    add virtualhost configurations for listening on ports 8080 and 443 (HTTPS).
  - Add selected ports to /etc/apache2/ports.conf
  - Add a simple HTML file /var/www/html/${virtual_host}/index.html indicating "This is a test!"
  - Enable the site.
  - Create .htpasswd for user (default: "user_guest"): /var/www/html/${virtual_host}/.htpasswd
    (a password must be entered twice).
  - Configure .htacess file for user: /var/www/html/${virtual_host}/.htaccess
    (pointing to the .htpasswd file).
  - Reload apache2 server to update configurations.

Verify in browser that the site is accessible and that a username ("user_guest")
and password are required to access the site:

    localhost/${virtual_host}
    localhost:8080
    localhost:443

Note: Port 8080 (instead of 80) is used as non-default port.
The script must run with privilege (see usage).
'

virtual_host='websiteA'
user='user_guest'

print_usage() {
	echo -e "apache2.sh: demo - installs apache2 and sets up a password-protected website
	Usage:
	sudo ./${0##*/}             Execute demo
	sudo ./${0##*/} [ -h ]      Print usage and exit\n"
}

is_apache_installed(){
	systemctl status apache2 &> /dev/null
	return "$?"
}

main() {
	# parse
	while getopts 'h' option; do
		case "$option" in
			h) print_usage; exit 0         ;;
			*) echo -e 'Incorrect usage!\n';
			   print_usage; exit 1         ;;
		esac
	done

	if [ "$EUID" != 0 ]; then
	    echo -e 'script requires sudo privilege.\n'
	    print_usage
	    exit 1
	fi

	is_apache_installed
	if [ "$?" -ne 0 ]; then
	    apt-get install apache2
	fi

	is_apache_installed || { echo 'apache2 failed to install. Exiting...'; exit 1; } 

	mkdir /var/www/html/"${virtual_host}"
	touch /etc/apache2/sites-available/"${virtual_host}".conf

	cat <<- EOF > /etc/apache2/sites-available/${virtual_host}.conf
	<VirtualHost *:8080 *:443>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html/${virtual_host}
	</VirtualHost>
	EOF

	cat <<- EOF >> /etc/apache2/ports.conf
	Listen 8080
	Listen 443
	EOF

	cat <<- EOF > /var/www/html/${virtual_host}/index.html
	<html>
	<body>
	<h1> This is a test! </h1>
	</body>
	</html>
	EOF

	a2ensite "${virtual_host}"
	systemctl reload apache2

	htpasswd -c /var/www/html/${virtual_host}/.htpasswd "$user"

	cat <<- EOF > /var/www/html/${virtual_host}/.htaccess
	AuthUserFile /var/www/html/${virtual_host}/.htpasswd
	AuthName 'Authentication required!'
	AuthType Basic
	require valid-user
	EOF

	cat <<- EOF >> /etc/apache2/apache2.conf
	<Directory /var/www/html>
	Options Indexes FollowSymLinks
	AllowOverride Authconfig
	Order allow,deny
	allow from all
	</Directory>
	EOF

	systemctl reload apache2
}

main "$@"
