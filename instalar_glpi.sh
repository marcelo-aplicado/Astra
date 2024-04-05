#!/bin/bash
echo "Atualizar e realizar upgrade no sistema..."
apt update -y
apt upgrade -y

echo "Instalação dos pacotes"
apt install -y xz-utils bzip2 unzip curl

echo "Instalação do WebService..."
apt install -y apache2 libapache2-mod-php php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2}

echo "Baixando e descompactando o GLPI na pasta /var/www/html"
wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.14/glpi-10.0.14.tgz | tar -zxv -C /var/www/html/

echo "Configurar permissões no diretório..."
chown www-data:www-data /var/www/html/glpi -Rf
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;

echo "Instalação do banco de dados..."
apt install -y mariadb-server

echo "Criação do banco de dados..."
mysql -e "create database glpidb character set utf8"
mysql -e "create user 'glpi'@'localhost' identified by 'glpi_aplicado'"
mysql -e "grant all privileges on glpidb.* to 'glpi'@'localhost' with grant option";
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -p -u root mysql
mysql -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Instalação do GLPI..."
php /var/www/html/glpi/bin/console glpi:database:install --db-host=localhost --db-name=glpidb --db-user=glpi --db-password=glpi_aplicado

echo "Reajustar permissões..."
chown www-data:www-data /var/www/html/glpi/files -Rf

echo "Corrigindo falhas de segurança..."
sed -i 's/$this->validated = false;/$this->validated = false;return;/g' /var/www/html/glpi/src/System/Requirement/SafeDocumentRoot.php
rm /var/www/html/glpi/install/install.php

echo "habilitando apache2 no inicializador ..."
systemctl enable apache2
systemctl restart apache2
