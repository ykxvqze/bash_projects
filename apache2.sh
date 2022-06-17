#!/usr/bin/env bash
: '
Demo - install apache2 web server and set up a password-protected virtual host.

USAGE: ./apache2.sh [ -h ]

OPTIONS:
      [ -h ]  Print usage

OUTPUT:
              Verify in browser: localhost/${virtual_host} (e.g. localhost/websiteA)

DESCRIPTION:

- Installs apache2 server if not already installed.
- Sets up a virtual host (e.g. by default in script: websiteA)
  - Create /var/www/html/"${virtual_host}"
  - Create /etc/apache2/sites-available/"${virtual_host}".conf and
    add virtualhost configuration for listening on ports 7000 and 443 (HTTPS).
  - Add selected ports to /etc/apache2/ports.conf
  - Add a simple HTML file /var/www/html/${virtual_host}/index.html indicating "This is a test!"
  - Enable the site.
  - Create .htpasswd for user (default: user_guest) /var/www/html/${virtual_host}/.htpasswd
    A password must be entered twice. 
  - Configure .htacess file for user: /var/www/html/${virtual_host}/.htaccess
    (pointing to the .htpasswd file).
  - Reload apache2 server to update configurations.

One can verify in browser that the site is accessible and that a username
("user_guest") and password are required to access the site:

    localhost/${virtual_host}
    localhost:7000
    localhost:443

Note: Port 7000 (instead of 80) was used in order to demonstrate how to
set up non-default ports. The script must run with privilege (see usage).

J.A., xrzfyvqk_k1jw@pm.me
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
	# Parse
	while getopts 'h' option; do
	case $option in
	    h) print_usage; exit 0         ;;
	    *) echo -e 'Incorrect usage!\n'; 
	       print_usage; exit 1         ;;
	esac
	done

	if [ "$EUID" != 0 ]; then
		exit 1
	fi

	is_apache_installed
	if [ "$?" -ne 0 ]; then
		apt-get install apache2
	fi

	mkdir /var/www/html/"${virtual_host}"
	touch /etc/apache2/sites-available/"${virtual_host}".conf

	cat <<- EOF > /etc/apache2/sites-available/${virtual_host}.conf
	<VirtualHost *:7000 *:443>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html/${virtual_host}
	</VirtualHost>
	EOF

	cat <<- EOF >> /etc/apache2/ports.conf
	Listen 7000
	Listen 443
	EOF

	cat <<- EOF > /var/www/html/${virtual_host}/index.html
	<html>
	<body>
	<h1> This is a test! </h1>
	</body>
	</html>
	EOF

	a2ensite ${virtual_host}
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
