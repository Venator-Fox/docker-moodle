#!/usr/bin/with-contenv /bin/bash

#Default runtime variables if none is supplied
NGINX_MAX_BODY_SIZE=${NGINX_MAX_BODY_SIZE:='1M'}

PHPFPM_UPLOAD_MAX_FILESIZE=${PHPFPM_UPLOAD_MAX_FILESIZE:='2M'}
PHPFPM_POST_MAX_SIZE=${PHPFPM_POST_MAX_SIZE:='8M'}
PHPFPM_MAX_EXECUTION_TIME=${PHPFPM_MAX_EXECUTION_TIME:='30'}

CRON_MOODLE_INTERVAL=${CRON_MOODLE_INTERVAL:='15'}

MOODLECFG_SSLPROXY=${MOODLECFG_SSLPROXY:='false'}
MOODLECFG_REVERSEPROXY=${MOODLECFG_REVERSEPROXY:='false'}
MOODLECFG_SESSION_HANDLER_CLASS=${MOODLECFG_SESSION_HANDLER_CLASS:='file'}

MOODLECFG_SESSION_MEMCACHED_SAVE_PATH=${MOODLECFG_SESSION_MEMCACHED_SAVE_PATH:='some-memcached:11211'}
MOODLECFG_SESSION_MEMCACHED_PREFIX=${MOODLECFG_SESSION_MEMCACHED_PREFIX:='memc.sess.key'}
MOODLECFG_SESSION_MEMCACHED_ACQUIRE_LOCK_TIMEOUT=${MOODLECFG_SESSION_MEMCACHED_ACQUIRE_LOCK_TIMEOUT:='120'}

MOODLECFG_SESSION_REDIS_HOST=${MOODLECFG_SESSION_REDIS_HOST:='some-redis'}
MOODLECFG_SESSION_REDIS_PORT=${MOODLECFG_SESSION_REDIS_PORT:='6379'}
MOODLECFG_SESSION_REDIS_DATABASE=${MOODLECFG_SESSION_REDIS_DATABASE:='0'}
MOODLECFG_SESSION_REDIS_PREFIX=${MOODLECFG_SESSION_REDIS_PREFIX:=''}
MOODLECFG_SESSION_REDIS_ACQUIRE_LOCK_TIMEOUT=${MOODLECFG_SESSION_REDIS_ACQUIRE_LOCK_TIMEOUT:='120'}
MOODLECFG_SESSION_REDIS_LOCK_EXPIRE=${MOODLECFG_SESSION_REDIS_LOCK_EXPIRE:='7200'}

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

case ${MOODLE_DBTYPE,,} in
    pgsql)  
        echo "[$(basename $0)] Database type is pgsql, installing pgsql client tools..."
        yum install -y rh-postgresql10-postgresql-syspaths > /dev/null
        echo "[$(basename $0)] Installed client tools."
        printf "[$(basename $0)] Waiting until postgres is ready... "
        until pg_isready -h $MOODLE_DBHOST -p $MOODLE_DBPORT; do
            (( ATTEMPT++ ))
            printf "[$(basename $0)] Waiting until postgres is ready ($ATTEMPT)... "
            sleep 1;
        done;
        echo "[$(basename $0)] Database is ready, removing pgsql client tools..."
        yum remove -y rh-postgresql10-postgresql rh-postgresql10-postgresql-libs rh-postgresql10-runtime > /dev/null
        echo "[$(basename $0)] Finished removing packages."
        ;;
    mysqli)
        echo "[$(basename $0)] Database type is mysqli, install mysql client tools..."
        yum install -y rh-mysql80-mysql-syspaths > /dev/null
        echo "[$(basename $0)] Installed client tools."
        echo "[$(basename $0)] Waiting until mysql is ready... "
        until mysqladmin ping -h"$MOODLE_DBHOST" -P$MOODLE_DBPORT -u$MOODLE_DBUSER -p$MOODLE_DBPASS &> /dev/null; do
            (( ATTEMPT++ ))
            echo "[$(basename $0)] Waiting until mysql is ready ($ATTEMPT)... connect to server at $MOODLE_DBHOST failed"
            sleep 1;
        done;
        echo "[$(basename $0)] Database is ready, removing mysql client tools..."
        yum remove -y rh-mysql80-lz4 rh-mysql80-mysql rh-mysql80-mysql-common rh-mysql80-mysql-config rh-mysql80-runtime > /dev/null
        echo "[$(basename $0)] Finished removing packages."
        ;;
    *)      
        >&2 echo "[$(basename $0)] Invalid \$MOODLE_DBTYPE $MOODLE_DBTYPE. Supported options are pgsql or mysqli."
        ;;
esac

echo "[$(basename $0)] Starting Moodle CLI installer if database tables are empty..."

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

echo "[$(basename $0)] Process complete."

echo "[$(basename $0)] Setting ownership..."
chown -R nginx:nginx /opt/rh/rh-nginx114/root/usr/share/nginx/html
echo "[$(basename $0)] Done setting ownership..."

if [ ! -f "/opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php" ]; then
    >&2 echo "[$(basename $0)] Something horrible has happened, config.php is missing. Check container logs to see if the Moodle CLI utility returned errors, I need to die now. Goodbye."
 kill -15 1
 sleep infinity
fi

#Set ephemeral configs
echo "[$(basename $0)] Setting ephemeral values in config.php..."
sed -i "/types_hash_max_size 2048;/a \    client_max_body_size $NGINX_MAX_BODY_SIZE;" /etc/opt/rh/rh-nginx114/nginx/nginx.conf
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $PHPFPM_UPLOAD_MAX_FILESIZE/g" /etc/opt/rh/rh-php72/php.ini
sed -i "s/post_max_size = 8M/post_max_size = $PHPFPM_POST_MAX_SIZE/g" /etc/opt/rh/rh-php72/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = $PHPFPM_MAX_EXECUTION_TIME/g" /etc/opt/rh/rh-php72/php.ini
sed -i "/\\\*sslproxy\\\*/,+1 d" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
sed -i "/\\\*wwwroot\\\*/i \$CFG->sslproxy = $MOODLECFG_SSLPROXY;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
sed -i "/\\\*reverseproxy\\\*/,+1 d" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
sed -i "/\\\*wwwroot\\\*/i \$CFG->reverseproxy = $MOODLECFG_REVERSEPROXY;\n" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php

sed -i "/\\\*reverseproxy\\\*/a\\\\n\$CFG->session_handler_class = '\\\core\\\session\\\\$MOODLECFG_SESSION_HANDLER_CLASS';" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php

#Only set ephemeral memcached config if session handler is memcached
if [ "$MOODLECFG_SESSION_HANDLER_CLASS" = "memcached" ]; then
    echo "[$(basename $0)] Session handler type env var is memcached. Inserting memcached configs..."
    sed -i "s/file/$MOODLECFG_SESSION_HANDLER_CLASS/g" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*session_handler_class\\\*/a\$CFG->session_memcached_save_path = '$MOODLECFG_SESSION_MEMCACHED_SAVE_PATH';" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*memcached_save_path\\\*/a\$CFG->session_memcached_prefix = '$MOODLECFG_SESSION_MEMCACHED_PREFIX';" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*memcached_prefix\\\*/a\$CFG->session_memcached_acquire_lock_timeout = $MOODLECFG_SESSION_MEMCACHED_ACQUIRE_LOCK_TIMEOUT;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    echo "[$(basename $0)] Completed memcached configuration."
else
    echo "[$(basename $0)] Session type env var is not memcached, skipping memcached configuration..."
fi

#Only set ephemeral redis config if session handler is redis
if [ "$MOODLECFG_SESSION_HANDLER_CLASS" = "redis" ]; then
    echo "[$(basename $0)] Session handler type env var is redis. Inserting redis configs..."
    sed -i "s/file/$MOODLECFG_SESSION_HANDLER_CLASS/g" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*session_handler_class\\\*/a\$CFG->session_redis_host = '$MOODLECFG_SESSION_REDIS_HOST';" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_host\\\*/a\$CFG->session_redis_port = $MOODLECFG_SESSION_REDIS_PORT;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_port\\\*/a\$CFG->session_redis_database = $MOODLECFG_SESSION_REDIS_DATABASE;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_database\\\*/a\$CFG->session_redis_prefix = '$MOODLECFG_SESSION_REDIS_PREFIX';" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_prefix\\\*/a\$CFG->session_redis_acquire_lock_timeout = $MOODLECFG_SESSION_REDIS_ACQUIRE_LOCK_TIMEOUT;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    sed -i "/\\\*session_redis_acquire_lock_timeout\\\*/a\$CFG->session_redis_lock_expire = $MOODLECFG_SESSION_REDIS_LOCK_EXPIRE;" /opt/rh/rh-nginx114/root/usr/share/nginx/html/config.php
    echo "[$(basename $0)] Completed redis configuration."
else
    echo "[$(basename $0)] Session type env var is not redis, skipping redis configuration..."
fi

echo "[$(basename $0)] Done setting values in config.php."

#Install plugins, if any
if [ ! ${#PLUGIN_DOWNLOAD_URL_ARRAY[@]} -eq 0 ]; then
    echo "[$(basename $0)] Plugins are to be installed, installing unzip..."
    yum install -y unzip > /dev/null
    echo "[$(basename $0)] installed unzip."
        for i in ${PLUGIN_DOWNLOAD_URL_ARRAY[@]}; do
                (( COUNTER++ ))
                ELEMENTS=${#PLUGIN_DOWNLOAD_URL_ARRAY[@]}
                PLUGIN_BASENAME=$(basename $i)
                PLUGIN_TYPE=$(echo $PLUGIN_BASENAME | awk -F '_' '{ print $1 }')
                PLUGIN_ARCHIVE_PATH=$MOODLE_WWW_ROOT$PLUGIN_TYPE/$PLUGIN_BASENAME

                echo "[$(basename $0)] Processing plugin ($COUNTER/$ELEMENTS): $PLUGIN_BASENAME"
                echo "[$(basename $0)] Plugin type determined to be: $PLUGIN_TYPE"
                echo "[$(basename $0)] Downloading $PLUGIN_BASENAME from $i..."

                curl -sS "$i" -o $PLUGIN_ARCHIVE_PATH > /dev/null

                echo "[$(basename $0)] Wrote archive to: $PLUGIN_ARCHIVE_PATH"

                echo "[$(basename $0)] Extracting $PLUGIN_BASENAME..."
                unzip -o $PLUGIN_ARCHIVE_PATH -d $MOODLE_WWW_ROOT$PLUGIN_TYPE > /dev/null
                rm -f $PLUGIN_ARCHIVE_PATH
                echo "[$(basename $0)] Removed $PLUGIN_ARCHIVE_PATH"

                echo "[$(basename $0)] Installed plugin $(echo $PLUGIN_BASENAME | awk -F '.' '{print $1}' )"
        done;
    echo "[$(basename $0)] Removing unzip..."
    yum remove unzip > /dev/null
    echo "[$(basename $0)] Removed unzip."
else
    echo "[$(basename $0)] Plugin env array is empty, skipping plugin install..."
fi

#Setup CRON
echo "*/$CRON_MOODLE_INTERVAL * * * * /usr/bin/php /opt/rh/rh-nginx114/root/usr/share/nginx/html/admin/cli/cron.php" > /etc/cron.d/moodle

#Self Destruct
echo "[$(basename $0)] Install complete, self destructing and exiting."
rm -- "$0" && exit 0
