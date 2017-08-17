### Supported tags and respective `Dockerfile` links

-	[`3.3`, `latest` (*3.3/Dockerfile*)](https://github.com/Venator-Fox/docker-moodle/blob/master/3.3/Dockerfile)

### How to use this image

Example: To startup an unconfigured local install with default values, no ssl:

Start a `postgres` server instance from the official postgres repository

```console

$ docker run --name moodle-postgres -e POSTGRES_PASSWORD=moodle -e POSTGRES_USER=moodle -e POSTGRES_DB=moodle -d postgres:latest
```

Start a `venatorfox/moodle` instance and link the postgres instance, expose port 80.

```console
$ docker run --name some-moodle -e MOODLE_WWWROOT=http://localhost --link moodle-postgres -p 80:80 venatorfox/moodle:latest
```

If this is a new db install, grab some coffee and wait until the webserver starts (indicated by [services.d] done in the log).
Visit the site at http://localhost, default unconfigured username is "admin" and password is "password". #superSecure 

See below for available runtime environment variables for a more specific configuration.

Volumes can be mounted for the moodledata, postgres data for persistant storage.

> The Moodle config.php will be created at run and baked into the Moodle Core Install.
> Like all of the other Moodle files, the config.php will be ephemeral, please do not edit it directly.
> Should changes be made, simply destroy the container and run it again with the desired runtime environment variables.

### Runtime Environment Variables

The following variables can be overridden at run or in docker-compose. 
Mutable variables update ephemeral container configs if run ontop of an existing db install from this image.
It is recommended to set them properly and not use default values. 
(Unless you want limits at 1M & no SSL, with your admin password being password (Can you not, kthx)).

| Variable | Default Value | Description | Mutable |
| ------ | ------ | ------ | ------ |
| NGINX_MAX_BODY_SIZE | 1M | Maximum allowed body size for NGINX | TRUE |
| PHPFPM_UPLOAD_MAX_FILESIZE | 2M | Maximum allowed upload filesize for PHP-FPM | TRUE |
| CRON_MOODLE_INTERVAL | 15 | Interval for Moodle Cron in Minutes | TRUE |
| MOODLECFG_SSLPROXY | false | Set to true if an SSL proxy container is put infront of the Moodle install, such as HAProxy with SSL termination. An example will be presented in the below docker compose files. | TRUE |
| MOODLE_LANG | en | ------ | FALSE |
| MOODLE_WWWROOT | http://localhost | Be sure to update to https:// if an SSL proxy is used. | TRUE |
| MOODLE_DBHOST | moodle-postgres | ------ | FALSE |
| MOODLE_DBNAME | moodle | ------ | FALSE |
| MOODLE_DBUSER | moodle | ------ | FALSE |
| MOODLE_DBPASS | moodle | ------ | FALSE |
| MOODLE_DBPORT | 5432 | ------ | FALSE |
| MOODLE_PREFIX | _mdl | ------ | FALSE |
| MOODLE_FULLNAME | Some Moodle Site Full Name | ------ | FALSE |
| MOODLE_SHORTNAME | Some Moodle Site Short Name | ------ | FALSE |
| MOODLE_SUMMARY | Some Moodle Summary | ------ | FALSE |
| MOODLE_ADMINUSER | admin | ------ | FALSE |
| MOODLE_ADMINPASS | password | ------ | FALSE |
| MOODLE_ADMINEMAIL | admin@example.com | Address of the Admin of Rainy Clouds, 42nd of Their Name , Breaker of Sanity, and ~~Destroyer~~ Protector of the AD Domain | FALSE |

### Maintenance

This is being actively maintained but has not yet been production tested. Please [Create an issue](https://github.com/Venator-Fox/docker-moodle/issues) if needed.

### Todos
 - Add some "is postgres ready?" wait instead of a timer on creation.

### More Complex Compose Example, SSL Termination with HAProxy

This example will run HAProxy with SSL termination for https://localhost.
Of course in actual production use a real CA, like LetsEncrypt.

Note that running this compose file will create files in `/opt/docker/volumes/` on your host.
You can remove this after toying with the example.

Run the following two commands:
```console
mkdir -p /opt/docker/volumes/moodle-haproxy/ssl
docker run --rm -v /opt/docker/volumes/moodle-haproxy/ssl:/ssl -e HOST=localhost -e TYPE=pem project42/selfsignedcert
```

Then, create this `haproxy.cfg` at `/opt/docker/volumes/moodle-haproxy/haproxy.cfg`
```console
global
    #debug
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    pidfile /var/run/haproxy.pid

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default ciphers to use on SSL-enabled listening sockets.
    ssl-default-bind-options   no-sslv3 no-tls-tickets force-tlsv12
    ssl-default-bind-ciphers   ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS

    spread-checks 4
    tune.maxrewrite 1024
    tune.ssl.default-dh-param 2048

defaults
    mode    http
    balance roundrobin

    option  dontlognull
    option  dontlog-normal
    option  redispatch

    maxconn 5000
    timeout connect 5s
    timeout client  20s
    timeout server  20s
    timeout queue   30s
    timeout http-request 5s
    timeout http-keep-alive 15s

frontend http-in
    bind *:80
    reqadd X-Forwarded-Proto:\ http
    default_backend nodes-http

frontend https-in
    bind *:443 ssl crt /etc/haproxy/ssl/localhost.pem
    reqadd X-Forwarded-Proto:\ https
    default_backend nodes-http

backend nodes-http
    redirect scheme https if !{ ssl_fc }
    server node1 moodle:80 check
```

Finally, save this v2 compose file as `docker-compose-example.yml` somewhere.
Run `docker-compose -f docker-compose-example.yml up` to bring the stack up.
Go get coffee. After install Visit https://localhost.
Use `docker-compose -f docker-compose-example.yml down` to destroy containers after playing.

```console
version: '2'

services:

  moodle-postgres:
    container_name: moodle-postgres
    image: postgres:9.6.3
    volumes:
      - /opt/docker/volumes/moodle-postgres/data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_PASSWORD=moodle
      - POSTGRES_USER=moodle
      - POSTGRES_DB=moodle
    restart: always

  moodle:
    container_name: moodle
    depends_on:
      - moodle-postgres
    image: venatorfox/moodle:3.3
    environment:
      - NGINX_MAX_BODY_SIZE=64M
      - PHPFPM_UPLOAD_MAX_FILESIZE=64M
      - CRON_MOODLE_INTERVAL=15
      - MOODLECFG_SSLPROXY=true
      - MOODLE_WWWROOT=https://localhost
      - MOODLE_DBHOST=moodle-postgres
      - MOODLE_DBNAME=moodle
      - MOODLE_DBUSER=moodle
      - MOODLE_DBPASS=moodle
      - MOODLE_FULLNAME=Educational Service Unit 10
      - MOODLE_SHORTNAME=ESU10
      - MOODLE_SUMMARY=This is the LMS for ESU10
      - MOODLE_ADMINUSER=admin
      - MOODLE_ADMINPASS=password
      - MOODLE_ADMINEMAIL=adam.zheng@esu10.org
    links:
      - moodle-postgres
    volumes:
      - /opt/docker/volumes/moodle/moodledata/:/var/www/moodledata/
    restart: always

  moodle-haproxy:
    container_name: moodle-haproxy
    image: million12/haproxy:1.7.8
    depends_on:
      - moodle
    links:
      - moodle
    ports:
      - 80:80
      - 443:443
    volumes:
      - /opt/docker/volumes/moodle-haproxy:/etc/haproxy
    restart: always
    cap_add:
      - NET_ADMIN
```

License
----
MIT
