#!/usr/bin/with-contenv /bin/bash

#Default runtime variables if none is supplied
NGINX_MAX_BODY_SIZE=${NGINX_MAX_BODY_SIZE:='1M'}
NGINX_KEEPALIVE_TIMEOUT=${NGINX_KEEPALIVE_TIMEOUT:='65'}
NGINX_SSL_SESSION_CACHE=${NGINX_SSL_SESSION_CACHE:='none'}
NGINX_SSL_SESSION_TIMEOUT=${NGINX_SSL_SESSION_TIMEOUT:='5m'}

PHPFPM_UPLOAD_MAX_FILESIZE=${PHPFPM_UPLOAD_MAX_FILESIZE:='2M'}
PHPFPM_POST_MAX_SIZE=${PHPFPM_POST_MAX_SIZE:='8M'}
PHPFPM_MAX_EXECUTION_TIME=${PHPFPM_MAX_EXECUTION_TIME:='30'}
PHPFPM_OPCACHE_MEMORY_CONSUMPTION=${PHPFPM_OPCACHE_MEMORY_CONSUMPTION:='128'}
PHPFPM_OPCACHE_MAX_ACCELERATED_FILES=${PHPFPM_OPCACHE_MAX_ACCELERATED_FILES:='4000'}

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
MOODLE_WWW_ROOT=/opt/rh/rh-nginx116/root/usr/share/nginx/html/

case ${MOODLE_DBTYPE,,} in
    pgsql)  
        echo "[$(basename $0)] Database type is pgsql."
        printf "[$(basename $0)] Waiting until postgres is ready... "
        until pg_isready -h $MOODLE_DBHOST -p $MOODLE_DBPORT; do
            (( ATTEMPT++ ))
            printf "[$(basename $0)] Waiting until postgres is ready ($ATTEMPT)... "
            sleep 1;
        done;
        echo "[$(basename $0)] Database is ready."
        ;;
    mysqli)
        echo "[$(basename $0)] Database type is mysqli."
        yum install -y rh-mysql80-mysql-syspaths > /dev/null
        echo "[$(basename $0)] Waiting until mysql is ready... "
        until mysqladmin ping -h"$MOODLE_DBHOST" -P$MOODLE_DBPORT -u$MOODLE_DBUSER -p$MOODLE_DBPASS &> /dev/null; do
            (( ATTEMPT++ ))
            echo "[$(basename $0)] Waiting until mysql is ready ($ATTEMPT)... connect to server at $MOODLE_DBHOST failed"
            sleep 1;
        done;
        echo "[$(basename $0)] Database is ready."
        ;;
    *)      
        >&2 echo "[$(basename $0)] Invalid \$MOODLE_DBTYPE $MOODLE_DBTYPE. Supported options are pgsql or mysqli."
        ;;
esac

echo "[$(basename $0)] Removing database client packages..."
yum remove -y rh-postgresql10-postgresql rh-postgresql10-postgresql-libs rh-postgresql10-runtime rh-mysql80-lz4 rh-mysql80-mysql rh-mysql80-mysql-common rh-mysql80-mysql-config rh-mysql80-runtime > /dev/null
echo "[$(basename $0)] Finished removing packages."

echo "[$(basename $0)] Starting Moodle CLI installer if database tables are empty..."

#Moodle CLI to install Moodle with runtime variables
/opt/rh/rh-php73/root/usr/bin/php /opt/rh/rh-nginx116/root/usr/share/nginx/html/admin/cli/install.php \
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

#Set ephemeral configs
echo "[$(basename $0)] Setting ephemeral values in config.php..."
sed -i "/types_hash_max_size 2048;/a \    client_max_body_size $NGINX_MAX_BODY_SIZE;" /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -i "s/keepalive_timeout  65;/keepalive_timeout  $NGINX_KEEPALIVE_TIMEOUT;/g" /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -i "s/ssl_session_cache    none;/ssl_session_cache    $NGINX_SSL_SESSION_CACHE;/g" /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -i "s/ssl_session_timeout  5m;/ssl_session_timeout  $NGINX_SSL_SESSION_TIMEOUT;/g" /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $PHPFPM_UPLOAD_MAX_FILESIZE/g" /etc/opt/rh/rh-php73/php.ini
sed -i "s/post_max_size = 8M/post_max_size = $PHPFPM_POST_MAX_SIZE/g" /etc/opt/rh/rh-php73/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = $PHPFPM_MAX_EXECUTION_TIME/g" /etc/opt/rh/rh-php73/php.ini
sed -i "s/opcache.memory_consumption=128/opcache.memory_consumption=$PHPFPM_OPCACHE_MEMORY_CONSUMPTION/g" /opt/rh/rh-php73/register.content/etc/opt/rh/rh-php73/php.d/10-opcache.ini
sed -i "s/opcache.max_accelerated_files=4000/opcache.max_accelerated_files=$PHPFPM_OPCACHE_MAX_ACCELERATED_FILES/g" /opt/rh/rh-php73/register.content/etc/opt/rh/rh-php73/php.d/10-opcache.ini
sed -i "/\\\*sslproxy\\\*/,+1 d" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
sed -i "/\\\*wwwroot\\\*/i \$CFG->sslproxy = $MOODLECFG_SSLPROXY;" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
sed -i "/\\\*reverseproxy\\\*/,+1 d" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
sed -i "/\\\*wwwroot\\\*/i \$CFG->reverseproxy = $MOODLECFG_REVERSEPROXY;\n" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php

sed -i "/\\\*reverseproxy\\\*/a\\\\n\$CFG->session_handler_class = '\\\core\\\session\\\\$MOODLECFG_SESSION_HANDLER_CLASS';" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php

#Only set ephemeral memcached config if session handler is memcached
if [ "$MOODLECFG_SESSION_HANDLER_CLASS" = "memcached" ]; then
    echo "[$(basename $0)] Session handler type env var is memcached. Inserting memcached configs..."
    sed -i "s/file/$MOODLECFG_SESSION_HANDLER_CLASS/g" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*session_handler_class\\\*/a\$CFG->session_memcached_save_path = '$MOODLECFG_SESSION_MEMCACHED_SAVE_PATH';" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*memcached_save_path\\\*/a\$CFG->session_memcached_prefix = '$MOODLECFG_SESSION_MEMCACHED_PREFIX';" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*memcached_prefix\\\*/a\$CFG->session_memcached_acquire_lock_timeout = $MOODLECFG_SESSION_MEMCACHED_ACQUIRE_LOCK_TIMEOUT;" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    echo "[$(basename $0)] Completed memcached configuration."

    echo "[$(basename $0)] Removing unneeded php extensions..."
    yum remove -y sclo-php73-php-pecl-redis5 > /dev/null
    echo "[$(basename $0)] Finished removing packages."

else
    echo "[$(basename $0)] Session type env var is not memcached, skipping memcached configuration..."
fi

#Only set ephemeral redis config if session handler is redis
if [ "$MOODLECFG_SESSION_HANDLER_CLASS" = "redis" ]; then
    echo "[$(basename $0)] Session handler type env var is redis. Inserting redis configs..."
    sed -i "s/file/$MOODLECFG_SESSION_HANDLER_CLASS/g" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*session_handler_class\\\*/a\$CFG->session_redis_host = '$MOODLECFG_SESSION_REDIS_HOST';" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_host\\\*/a\$CFG->session_redis_port = $MOODLECFG_SESSION_REDIS_PORT;" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_port\\\*/a\$CFG->session_redis_database = $MOODLECFG_SESSION_REDIS_DATABASE;" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_database\\\*/a\$CFG->session_redis_prefix = '$MOODLECFG_SESSION_REDIS_PREFIX';" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*redis_prefix\\\*/a\$CFG->session_redis_acquire_lock_timeout = $MOODLECFG_SESSION_REDIS_ACQUIRE_LOCK_TIMEOUT;" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    sed -i "/\\\*session_redis_acquire_lock_timeout\\\*/a\$CFG->session_redis_lock_expire = $MOODLECFG_SESSION_REDIS_LOCK_EXPIRE;" /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
    echo "[$(basename $0)] Completed redis configuration."

    echo "[$(basename $0)] Removing unneeded php extensions..."
    yum remove -y sclo-php73-php-pecl-memcached > /dev/null
    echo "[$(basename $0)] Finished removing packages."

else
    echo "[$(basename $0)] Session type env var is not redis, skipping redis configuration..."
fi

echo "[$(basename $0)] Done setting values in config.php."

#Snakeoil
echo "[$(basename $0)] Generating keys..."
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/opt/rh/rh-nginx116/nginx/cert.key -out /etc/opt/rh/rh-nginx116/nginx/cert.pem -subj "/CN=$(hostname)" &> /dev/null
echo "[$(basename $0)] Done generating keys."

echo "[$(basename $0)] Set ownership..."
chown nginx:nginx /opt/rh/rh-nginx116/root/usr/share/nginx/html/config.php
echo "[$(basename $0)] Done setting ownership..."

#Install plugins, if any
if [ ! ${#PLUGIN_DOWNLOAD_URL_ARRAY[@]} -eq 0 ]; then

    echo "[$(basename $0)] Plugins are to be installed..."

    declare -A PLUGIN_TYPE_MAP
    PLUGIN_TYPE_MAP["mod"]="mod/"
    PLUGIN_TYPE_MAP["antivirus"]="lib/antivirus/"
    PLUGIN_TYPE_MAP["assignsubmission"]="mod/assign/submission/"
    PLUGIN_TYPE_MAP["assignfeedback"]="mod/assign/feedback/"
    PLUGIN_TYPE_MAP["booktool"]="mod/book/tool/"
    PLUGIN_TYPE_MAP["datafield"]="mod/data/field/"
    PLUGIN_TYPE_MAP["datapreset"]="mod/data/preset/"
    PLUGIN_TYPE_MAP["ltisource"]="mod/lti/source/"
    PLUGIN_TYPE_MAP["fileconverter"]="files/converter/"
    PLUGIN_TYPE_MAP["ltiservice"]="mod/lti/service/"
    PLUGIN_TYPE_MAP["mlbackend"]="lib/mlbackend/"
    PLUGIN_TYPE_MAP["quiz"]="mod/quiz/report/"
    PLUGIN_TYPE_MAP["quizaccess"]="mod/quiz/accessrule/"
    PLUGIN_TYPE_MAP["scormreport"]="mod/scorm/report/"
    PLUGIN_TYPE_MAP["workshopform"]="mod/workshop/form/"
    PLUGIN_TYPE_MAP["workshopallocation"]="mod/workshop/allocation/"
    PLUGIN_TYPE_MAP["workshopeval"]="mod/workshop/eval/"
    PLUGIN_TYPE_MAP["block"]="blocks/"
    PLUGIN_TYPE_MAP["qtype"]="question/type/"
    PLUGIN_TYPE_MAP["qbehaviour"]="question/behaviour/"
    PLUGIN_TYPE_MAP["qformat"]="question/format/"
    PLUGIN_TYPE_MAP["filter"]="filter/"
    PLUGIN_TYPE_MAP["editor"]="lib/editor/"
    PLUGIN_TYPE_MAP["atto"]="lib/editor/atto/plugins/"
    PLUGIN_TYPE_MAP["tinymce"]="lib/editor/tinymce/plugins/"
    PLUGIN_TYPE_MAP["enrol"]="enrol/"
    PLUGIN_TYPE_MAP["auth"]="auth/"
    PLUGIN_TYPE_MAP["tool"]="admin/tool/"
    PLUGIN_TYPE_MAP["logstore"]="admin/tool/log/store/"
    PLUGIN_TYPE_MAP["availability"]="availability/condition/"
    PLUGIN_TYPE_MAP["calendartype"]="calendar/type/"
    PLUGIN_TYPE_MAP["message"]="message/output/"
    PLUGIN_TYPE_MAP["format"]="course/format/"
    PLUGIN_TYPE_MAP["dataformat"]="dataformat/"
    PLUGIN_TYPE_MAP["profilefield"]="user/profile/field/"
    PLUGIN_TYPE_MAP["report"]="report/"
    PLUGIN_TYPE_MAP["coursereport"]="course/report/"
    PLUGIN_TYPE_MAP["gradeexport"]="grade/export/"
    PLUGIN_TYPE_MAP["gradeimport"]="grade/import/"
    PLUGIN_TYPE_MAP["gradereport"]="grade/report/"
    PLUGIN_TYPE_MAP["gradingform"]="grade/grading/form/"
    PLUGIN_TYPE_MAP["mnetservice"]="mnet/service/"
    PLUGIN_TYPE_MAP["webservice"]="webservice/"
    PLUGIN_TYPE_MAP["repository"]="repository/"
    PLUGIN_TYPE_MAP["portfolio"]="portfolio/"
    PLUGIN_TYPE_MAP["search"]="search/engine/"
    PLUGIN_TYPE_MAP["media"]="media/player/"
    PLUGIN_TYPE_MAP["plagiarism"]="plagiarism/"
    PLUGIN_TYPE_MAP["cachestore"]="cache/stores/"
    PLUGIN_TYPE_MAP["cachelock"]="cache/locks/"
    PLUGIN_TYPE_MAP["theme"]="theme/"
    PLUGIN_TYPE_MAP["local"]="local/"
    PLUGIN_TYPE_MAP["assignment"]="mod/assignment/type/"
    PLUGIN_TYPE_MAP["report"]="admin/report/"

    for i in ${PLUGIN_DOWNLOAD_URL_ARRAY[@]}; do
        (( COUNTER++ ))
        ELEMENTS=${#PLUGIN_DOWNLOAD_URL_ARRAY[@]}
        PLUGIN_BASENAME=$(basename $i)
        PLUGIN_TYPE_COMPONENT=$(echo $PLUGIN_BASENAME | awk -F '_' '{ print $1 }')
        PLUGIN_TYPE_PATH=${PLUGIN_TYPE_MAP["$PLUGIN_TYPE_COMPONENT"]}

        PLUGIN_ARCHIVE_PATH=$MOODLE_WWW_ROOT$PLUGIN_TYPE_PATH$PLUGIN_BASENAME

        echo "[$(basename $0)] Processing plugin ($COUNTER/$ELEMENTS): $PLUGIN_BASENAME"

        echo "[$(basename $0)] Determine plugin component name..."
        if [ -n "${PLUGIN_TYPE_MAP[$PLUGIN_TYPE_COMPONENT] + 1}" ]; then
            echo "[$(basename $0)] Plugin component name determined to be: $PLUGIN_TYPE_COMPONENT"
        else
            >&2 echo "[$(basename $0)] Unable to determine plugin component name. Something horrible has happened, please double check the URL and previous errors if any. Submit an issue with logs if needed. I need to die now. Goodbye.";
            kill -15 1; exit 10
        fi

        echo "[$(basename $0)] Plugin archive path determined to be: $PLUGIN_ARCHIVE_PATH"
        echo "[$(basename $0)] Downloading $PLUGIN_BASENAME from $i..."

        curl -sS "$i" -o $PLUGIN_ARCHIVE_PATH > /dev/null
        echo "[$(basename $0)] Wrote archive to: $PLUGIN_ARCHIVE_PATH"

        echo "[$(basename $0)] Extracting $PLUGIN_BASENAME to $MOODLE_WWW_ROOT$PLUGIN_TYPE_PATH"
        unzip -o $PLUGIN_ARCHIVE_PATH -d $MOODLE_WWW_ROOT$PLUGIN_TYPE_PATH > /dev/null

        rm -f $PLUGIN_ARCHIVE_PATH
        echo "[$(basename $0)] Removed $PLUGIN_ARCHIVE_PATH"

        echo -e "[$(basename $0)] Installed plugin $(echo $PLUGIN_BASENAME | awk -F '.' '{print $1}' )\n"
    done;
else
    echo "[$(basename $0)] Plugin env array is empty, skipping plugin install..."
fi

#Setup CRON
echo "*/$CRON_MOODLE_INTERVAL * * * * /usr/bin/php /opt/rh/rh-nginx116/root/usr/share/nginx/html/admin/cli/cron.php" > /etc/cron.d/moodle

#Remove git, openssl, unzip
echo "[$(basename $0)] Removing unneeded script packages..."
yum remove -y fipscheck groff-base libedit openssh rsync make unzip > /dev/null
echo "[$(basename $0)] Finished removing packages."

#Self Destruct
echo "[$(basename $0)] Install complete, self destructing and exiting."
rm -- "$0" && exit 0
