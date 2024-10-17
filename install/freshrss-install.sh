#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y rsync
$STD apt-get install -y apache2
$STD apt-get install -y php
$STD apt-get install -y php-curl php-gmp php-intl php-mbstring php-xml php-zip php-sqlite3 php-mysql php-pgsql php-gd
$STD apt-get install -y mariadb-server
msg_ok "Installed Dependencies"

RELEASE=$(curl -sL https://api.github.com/repos/FreshRSS/FreshRSS/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
msg_info "Installing FreshRSS ${RELEASE}"
mkdir -p /var/www/FreshRSS
wget -q https://github.com/FreshRSS/FreshRSS/archive/${RELEASE}.tar.gz
tar -xzf ${RELEASE}.tar.gz
cp -r FreshRSS-${RELEASE}/* /var/www/FreshRSS/
chown -R www- /var/www/FreshRSS/
find /var/www/FreshRSS/ -type d -exec chmod 755 {} \;
find /var/www/FreshRSS/ -type f -exec chmod 644 {} \;
chmod -R 777 /var/www/FreshRSS/data/
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed FreshRSS ${RELEASE}"

msg_info "Configuring Apache"
cat <<EOF > /etc/apache2/sites-available/freshrss.conf
<VirtualHost *:80>
    DocumentRoot /var/www/FreshRSS/p
    <Directory /var/www/FreshRSS/p>
        AllowOverride All
        Require all granted
        Options -Indexes
    </Directory>
</VirtualHost>
EOF
a2ensite freshrss
a2enmod rewrite
systemctl restart apache2
msg_ok "Configured Apache"

msg_info "Setting up database"
mysql -e "CREATE DATABASE freshrss;"
mysql -e "CREATE USER 'freshrss'@'localhost' IDENTIFIED BY 'freshrss_password';"
mysql -e "GRANT ALL PRIVILEGES ON freshrss.* TO 'freshrss'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
msg_ok "Set up database"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf FreshRSS-${RELEASE} ${RELEASE}.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

msg_info "FreshRSS installation completed"
echo "Please complete the installation by accessing the web interface at http://your-server-ip/p/"
echo "Use the following database information during the web setup:"
echo "Database Type: MySQL"
echo "Host: localhost"
echo "Database Name: freshrss"
echo "Username: freshrss"
echo "Password: freshrss_password"
echo "Remember to change the database password after installation!"
msg_ok "Ready for web-based setup"