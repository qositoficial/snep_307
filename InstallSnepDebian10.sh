# Script de instalação do SNEP 3.07 Community para Debian 10
# Script criado com base em um PDF do grupo do SNEP no Telegram
# Autor do script: Diego Romanio de Almeida @diegoromanio

#####
echo "Iniciando instalação ..."
sleep 1

#####
echo "Ajustando cores do shell ..."
cd ~
rm -rf ~/.bashrc
cp /etc/skel/.bashrc ~/
echo ":syntax enable" >> .vimrc
exec bash

#####
echo "Fazendo ajustes no path ..."
cat <<EOF >>/root/.bashrc
export PATH="/usr/local/sbin/:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"
EOF
source ~/.bashrc
sleep 1

#####
echo "Vou ajustar os repositórios do php5 ..."
apt update && apt install -y software-properties-common apt-transport-https curl gnupg1 gnupg2 vim wget curl sudo
curl https://packages.sury.org/php/apt.gpg | apt-key add -
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php5.list
apt update && apt upgrade -y && apt autoremove -y
sleep 1

#####
echo "Agora vamos instalar os pacotes necessários ..."
apt install -y apt-transport-https apache2 mariadb-server htop unzip mc ncdu xmlstarlet git unixodbc unixodbc-dev odbcinst1debian2 libncurses5-dev g++ build-essential lshw libjansson-dev libssl-dev sox sqlite3 libsqlite3-dev libxml2-dev uuid-dev libcurl4-openssl-dev libvorbis-dev libmariadbclient-dev dialog python locate rsyslog wget php5.6 php5.6-fpm php5.6-cgi php5.6-mysql php5.6-gd php5.6-curl php5.6-opcache php5.6-xml libgd-tools php-pear
sleep 1

#####
echo "Fazendo ajustes para utilizar o php5 ..."
update-alternatives --set php /usr/bin/php5.*
sed -i s/"register_argc_argv = Off"/"register_argc_argv = On"/g /etc/php/5.*/cgi/php.ini
sed -i s/"register_argc_argv = Off"/"register_argc_argv = On"/g /etc/php/5.*/cli/php.ini
sed -i s/"register_argc_argv = Off"/"register_argc_argv = On"/g /etc/php/5.*/fpm/php.ini
a2enmod proxy_fcgi setenvif
a2enconf php5.6-fpm
systemctl reload apache2 && systemctl restart apache2
sleep 1

#####
echo "Instalndo o asterisk 13.38.3 ..."
cd /usr/src/
wget -c http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-13.38.3.tar.gz
tar -zxf asterisk-13.38.3.tar.gz
cd /usr/src/asterisk-13.38.3/
./configure
make menuselect.makeopts
menuselect/menuselect --enable res_config_mysql --enable app_mysql --enable app_meetme --enable cdr_mysql --enable EXTRA-SOUNDS-EN-GSM 
make
make install
sleep 1

#####
echo "Ajustando inicializador asterisk ..."
cp contrib/init.d/rc.debian.asterisk /etc/init.d/asterisk
chmod +x /etc/init.d/asterisk
update-rc.d asterisk defaults
sed -i s/"DAEMON=__ASTERISK_SBIN_DIR__\/asterisk"/"DAEMON=\/usr\/sbin\/asterisk"/g /etc/init.d/asterisk
sed -i s/"ASTVARRUNDIR=__ASTERISK_VARRUN_DIR__"/"ASTVARRUNDIR=\/var\/run\/asterisk"/g /etc/init.d/asterisk
sed -i s/"ASTETCDIR=__ASTERISK_ETC_DIR__"/"ASTETCDIR=\/etc\/asterisk"/g /etc/init.d/asterisk
rm -rf /usr/src/asterisk*
sleep 1

#####
echo "Ajustando mariadb ..."
sqlmode=$(cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep "sql-mode=NO_ENGINE_SUBSTITUTION")
if [ "$sqlmode" != "sql-mode=NO_ENGINE_SUBSTITUTION" ]; then
        sed -i '/mariadb]/asql-mode=NO_ENGINE_SUBSTITUTION' /etc/mysql/mariadb.conf.d/50-server.cnf
fi
systemctl restart mariadb
sleep 1

#####
echo "Ajustando tela de login ..."
echo "#######   #######   ##    ##        ##  #######
########  ########  ##    ##        ##  ########
##    ##  ##    ##   ##  ##         ##  ##    ##
##    ##  ##    ##   ##  ##         ##  ##    ##
########  ########    ####    ####  ##  ########
#######   ########    ####    ####  ##  #######
##        ##    ##   ##  ##         ##  ##
##        ##    ##   ##  ##         ##  ##
##        ########  ##    ##        ##  ##
##        #######   ##    ##        ##  ##
" > /etc/issue
sleep 1

#####
echo "Iniciando a instalação do snep 3 ..."
cd /var/www/html/
rm -rf /var/www/html/*
wget -c https://bitbucket.org/snepdev/snep-3/get/master.tgz -O snep-3.tgz
wget -c https://bitbucket.org/snepdev/billing/get/master.tar.gz -O snep-billing.tgz
wget -c https://bitbucket.org/snepdev/ivr/get/master.tar.gz -O snep-ivr.tgz
tar xf snep-3.tgz
tar xf snep-billing.tgz
tar xf snep-ivr.tgz
sleep 1

#####
echo "Ajustando arquivos do snep 3 ..."
mv snepdev-snep-3* snep
cd snepdev-billing*
tar cf - . | tar xvf - -C ../snep/modules/billing/
cd /var/www/html/
cd snepdev-ivr*
tar cf - . | tar xvf - -C ../snep/modules/ivr/
cd /var/www/html/
sleep 1

#####
echo "Ajustes para o snep 3 ..."
mkdir -p /var/log/snep
cd /var/log/snep
touch ui.log
touch agi.log
ln -s /var/log/asterisk/full full
chown -R www-data.www-data *
cd /var/www/html/snep/
ln -s /var/log/snep logs
cd /var/lib/asterisk/agi-bin/
ln -s /var/www/html/snep/agi/ snep
cd /etc/apache2/sites-enabled/
ln -s /var/www/html/snep/install/snep.apache2 001-snep
cd /var/spool/asterisk/
rm -rf monitor
ln -sf /var/www/html/snep/arquivos monitor
sed -i s/'itc_required = "true"'/'itc_required = "false"'/g /var/www/html/snep/includes/setup.conf
sed -i s/'itc_distro = "1"'/'itc_distro = "0"'/g /var/www/html/snep/includes/setup.conf
sed -i s/'emp_nome = "Opens Tecnologia"'/'emp_nome = "PBX-IP"'/g /var/www/html/snep/includes/setup.conf
sleep 1

#####
echo "Importando banco de dados snep 3..."
cd /var/www/html/snep/install/database
mysql -u root < database.sql
mysql -u root snep < schema.sql
mysql -u root snep < system_data.sql
mysql -u root snep < core-cnl.sql
mysql -u root snep < /var/www/html/snep/modules/billing/install/schema.sql
mysql -u root snep < update/3.06/update.sql
mysql -u root snep < update/3.06.1/update.sql
mysql -u root snep < update/3.06.2/update.sql
mysql -u root snep < update/3.07/update.sql
sleep 1

#####
echo "Instalando arquivos de áudio para asterisk/ snep 3 ..."
rm -rf /var/lib/asterisk/sounds/*
cd /var/www/html/snep/install/sounds
mkdir -p /var/lib/asterisk/sounds/en
tar -xzf asterisk-core-sounds-en-wav-current.tar.gz -C /var/lib/asterisk/sounds/en
tar -xzf asterisk-extra-sounds-en-wav-current.tar.gz -C /var/lib/asterisk/sounds/en
mkdir -p /var/lib/asterisk/sounds/es
tar -xzf asterisk-core-sounds-es-wav-current.tar.gz -C /var/lib/asterisk/sounds/es
mkdir -p /var/lib/asterisk/sounds/pt_BR
tar -xzf asterisk-core-sounds-pt_BR-wav.tgz -C /var/lib/asterisk/sounds/pt_BR
cd /var/lib/asterisk/sounds
mkdir -p es/tmp es/backup en/tmp en/backup pt_BR/tmp pt_BR/backup
chown -R www-data:www-data *
mkdir -p /var/www/html/snep/sounds
cd /var/www/html/snep/sounds/
ln -sf /var/lib/asterisk/moh/ moh
ln -sf /var/lib/asterisk/sounds/pt_BR/ pt_BR
cd /var/lib/asterisk/moh
mkdir -p tmp backup
chown -R www-data.www-data /var/lib/asterisk/moh
rm -rf *-asterisk-moh-opsound-wav
sleep 1

#####
echo "Ajustando permissões de arquivos snep 3 ..."
cat <<EOF >/var/www/html/index.html
<html>
<body>
<meta http-equiv="Refresh" content="0; url='snep'">
</body>
</html>
EOF
rm -rf /var/www/html/snep-*
rm -rf /var/www/html/snepdev-*
cd /var/www/html/
find . -type f -exec chmod 640 {} \; -exec chown www-data:www-data {} \;
find . -type d -exec chmod 755 {} \; -exec chown www-data:www-data {} \;
chmod +x /var/www/html/snep/agi/*
sleep 1

#####
echo "Atualizando Configuração Asterisk ..."
mv -b -f /var/www/html/snep/install/etc/asterisk /etc/
chown -R www-data.www-data /etc/asterisk/snep
cat <<EOF >/etc/odbcinst.ini
#####PBX-IP#####
[MySQL]
Description = MySQL ODBC MyODBC Driver
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
FileUsage = 1
[Text]
Description = ODBC for Text Files
Driver = /usr/lib/x86_64-linux-gnu/odbc/libodbctxtS.so
Setup = /usr/lib/x86_64-linux-gnu/odbc/libodbctxtS.so
FileUsage = 1
CPTimeout =
CPReuse =
EOF
cat <<EOF >/etc/odbc.ini
#####PBX-IP#####
[MySQL-snep]
Description = MySQL ODBC Driver
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
Socket = /var/run/mysqld/mysqld.sock
Server = localhost
User = snep
Password = sneppass
Database = snep
Option = 3
EOF
sleep 1

#####
echo "Baixando connector-odbc ..."
mkdir -p /root/libmaodbc
cd /root/libmaodbc
wget -c https://downloads.mariadb.com/Connectors/odbc/connector-odbc-2.0.19/mariadb-connector-odbc-2.0.19-ga-debian-x86_64.tar.gz
tar -xzf mariadb-connector-odbc-2.0.19-ga-debian-x86_64.tar.gz
cp lib/libmaodbc.so /usr/lib/x86_64-linux-gnu/odbc/
cd /root
rm -rf /root/libmaodbc
sleep 1

#####
echo "Instalação finalizada, reincie o servidor e inicie as configurações!"
