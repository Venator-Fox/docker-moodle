#!/usr/bin/with-contenv /bin/bash

#Default runtime variables if none is supplied
NGINX_MAX_BODY_SIZE=${NGINX_MAX_BODY_SIZE:='1M'}
PHPFPM_UPLOAD_MAX_FILESIZE=${PHPFPM_UPLOAD_MAX_FILESIZE:='2M'}
PHPFPM_POST_MAX_SIZE=${PHPFPM_POST_MAX_SIZE:='8M'}
PHPFPM_MAX_EXECUTION_TIME=${PHPFPM_MAX_EXECUTION_TIME:='30'}
CRON_MOODLE_INTERVAL=${CRON_MOODLE_INTERVAL:='15'}
MOODLECFG_SSLPROXY=${MOODLECFG_SSLPROXY:='false'}
MOODLECFG_REVERSEPROXY=${MOODLECFG_REVERSEPROXY:='false'}

MOODLE_LANG=${MOODLE_LANG:='en'}
MOODLE_WWWROOT=${MOODLE_WWWROOT:='http://localhost'}
MOODLE_DBTYPE=${MOODLE_DBTYPE:='pgsql'}
MOODLE_DBHOST=${MOODLE_DBHOST:='moodle-postgres'}
MOODLE_DBNAME=${MOODLE_DBNAME:='moodle'}
MOODLE_DBUSER=${MOODLE_DBUSER:='moodle'}
MOODLE_DBPASS=${MOODLE_DBPASS:='moodle'}
MOODLE_DBPORT=${MOODLE_DBPORT:='5432'}
MOODLE_PREFIX=${MOODLE_PREFIX:='mdl_'}
MOODLE_FULLNAME=${MOODLE_FULLNAME:='Some Moodle Site Full Name'}
MOODLE_SHORTNAME=${MOODLE_SHORTNAME:='Some Moodle Site Short Name'}
MOODLE_SUMMARY=${MOODLE_SUMMARY:='Some Moodle Summary'}
MOODLE_ADMINUSER=${MOODLE_ADMINUSER:='admin'}
MOODLE_ADMINPASS=${MOODLE_ADMINPASS:='password'}
MOODLE_ADMINEMAIL=${MOODLE_ADMINEMAIL:='support@example.com'}

INSTALL_PLUGIN_URLS=${INSTALL_PLUGIN_URLS:=}

PLUGIN_DOWNLOAD_URL_ARRAY=($INSTALL_PLUGIN_URLS)
MOODLE_WWW_ROOT=/opt/rh/rh-nginx114/root/usr/share/nginx/html/

#Install plugins, if any
if [ ! ${#PLUGIN_DOWNLOAD_URL_ARRAY[@]} -eq 0 ]; then
    echo "[INFO] Plugins are to be installed, installing unzip..."
    yum install -y unzip > /dev/null
    echo "[INFO] installed unzip."
        for i in ${PLUGIN_DOWNLOAD_URL_ARRAY[@]}; do
                ELEMENTS=${#PLUGIN_DOWNLOAD_URL_ARRAY[@]}
                COUNTER=1
                PLUGIN_BASENAME=$(basename $i)
                PLUGIN_TYPE=$(echo $PLUGIN_BASENAME | awk -F '_' '{ print $1 }')
                PLUGIN_ARCHIVE_PATH=$MOODLE_WWW_ROOT$PLUGIN_TYPE/$PLUGIN_BASENAME

                echo "[INFO] Processing plugin ($COUNTER/$ELEMENTS): $PLUGIN_BASENAME"
                echo "[INFO] Plugin type determined to be: $PLUGIN_TYPE"
                echo "[INFO] Downloading $PLUGIN_BASENAME from $i..."

                curl -sS "$i" -o $PLUGIN_ARCHIVE_PATH > /dev/null

                echo "[INFO] Wrote archive to: $PLUGIN_ARCHIVE_PATH"

                echo "[INFO] Extracting $PLUGIN_BASENAME..."
                unzip -o $PLUGIN_ARCHIVE_PATH -d $MOODLE_WWW_ROOT$PLUGIN_TYPE > /dev/null
                rm -f $PLUGIN_ARCHIVE_PATH
                echo "[INFO] Removed $PLUGIN_ARCHIVE_PATH"

                echo "[INFO] Installed plugin $(echo $PLUGIN_BASENAME | awk -F '.' '{print $1}' )"

                (( COUNTER++ ))
        done;
    echo "[INFO] Removing unzip..."
    yum remove unzip > /dev/null
    echo "[INFO] Removed unzip."
else
    echo "[INFO] Plugin env array is empty, skipping plugin install..."
fi

#This is terrible, TODO to actually wait until the DB is up. For now this works but wastes 30 seconds if recreating the container.
sleep 30;

#Moodle CLI to install Moodle with runtime variables
/opt/rh/rh-php72/root/usr/bin/php /opt/rh/rh-nginx114/root/usr/share/nginx/html/admin/cli/install.php \
  --chmod=2777 \
  --lang=$MOODLE_LANG \
  --wwwroot=$MOODLE_WWWROOT \
  --dataroot=/var/moodledata \
  --dbtype=$MOODLE_DBTYPE \
  --dbhost=$MOODLE_DBHOST \
  --dbname=$MOODLE_DBNAME \
  --dbuser=$MOODLE_DBUSER \
  --dbpass=$MOODLE_DBPASS \
  --dbport=$MOODLE_DBPORT \
  --prefix=$MOODLE_PREFIX \
  --fullname="$MOODLE_FULLNAME" \
  --shortname="$MOODLE_SHORTNAME" \
  --summary="$MOODLE_SUMMARY" \
  --adminuser=$MOODLE_ADMINUSER \
  --adminpass=$MOODLE_ADMINPASS \
  --adminemail=$MOODLE_ADMINEMAIL \
  --agree-license \
  --non-interactive

chown -R nginx:nginx /opt/rh/rh-nginx114/root/usr/share/nginx/html

#Set ephemeral configs
sed -i "/types_hash_max_size 2048;/a \    client_max_body_size $NGINX_MAX_BODY_SIZE;" /etc/opt/rh/rh-nginx114/nginx/nginx.conf
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $PHPFPM_UPLOAD_MAX_FILESIZE/g" /etc/opt/rh/rh-php72/php.ini
sed -i "s/post_max_size = 8M/post_max_size = $PHPFPM_POST_MAX_SIZE/g" /etc/opt/rh/rh-php72/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = $PHPFPM_MAX_EXECUTION_TIME/g" /etc/opt/rh/rh-php72/php.ini
sed -i "/\\\*sslproxy\\\*/,+1 d" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
sed -i "/\\\*wwwroot\\\*/i \$CFG->sslproxy = $MOODLECFG_SSLPROXY;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
sed -i "/\\\*reverseproxy\\\*/,+1 d" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
sed -i "/\\\*wwwroot\\\*/i \$CFG->reverseproxy = $MOODLECFG_REVERSEPROXY;\n" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php

#Setup CRON
echo "*/$CRON_MOODLE_INTERVAL * * * * /usr/bin/php /opt/rh/rh-nginx114/root/usr/share/nginx/html/admin/cli/cron.php" > /etc/cron.d/moodle

#Self Destruct
echo "[install-moodle.sh] Install complete, self destructing and exiting."
rm -- "$0" && exit 0
