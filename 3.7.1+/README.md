[![](https://images.microbadger.com/badges/version/venatorfox/moodle:3.7.1.svg)](http://git.moodle.org/gw?p=moodle.git;a=tree;hb=refs/heads/MOODLE_37_STABLE "MOODLE_37_STABLE (3.7.1+)") [![](https://images.microbadger.com/badges/image/venatorfox/moodle:3.7.1.svg)](https://microbadger.com/images/venatorfox/moodle "View image metadata on MicroBadger") [![Pulls on Docker Hub](https://img.shields.io/docker/pulls/venatorfox/moodle.svg)](https://hub.docker.com/r/venatorfox/moodle)  [![Stars on Docker Hub](https://img.shields.io/docker/stars/venatorfox/moodle.svg)](https://hub.docker.com/r/venatorfox/moodle) [![GitHub Open Issues](https://img.shields.io/github/issues/Venator-Fox/docker-moodle.svg)](https://github.com/Venator-Fox/docker-moodle/issues) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Supported tags and respective `Dockerfile` links
> ~~Depreciated~~ builds are not recommended, as they are EOL.
> ##### NOTICE: The container [overhaul to CentOS](https://github.com/Venator-Fox/docker-moodle/commit/07a7cd33202a2aff8b04b5647f2b5569ce2003a0) changes the location of `moodledata`. It is now located in `/var/moodledata`. Please update persistent mounts if upgrading. This is as of the `3.7.1` build. Depreciated builds (3.4.1+ and below) use `/var/www/moodledata`.

-   [`3.7.1`, `latest` (*3.7.1/Dockerfile*)](https://github.com/Venator-Fox/docker-moodle/blob/master/3.7.1%2B/Dockerfile)
-   ~~[`3.4.1`, (*3.4.1/Dockerfile*)](https://github.com/Venator-Fox/docker-moodle/blob/master/3.4.1%2B/Dockerfile)~~
-   ~~[`3.3.4`, (*3.3.4/Dockerfile*)](https://github.com/Venator-Fox/docker-moodle/blob/master/3.3.4%2B/Dockerfile)~~
-   ~~[`3.0.10`, (*3.0.10/Dockerfile*)](https://github.com/Venator-Fox/docker-moodle/blob/master/3.0.10/Dockerfile)~~

Now with plugin support via `docker -e`!

### How to use this image

Example: To startup a super basic, unconfigured local install with default values, no ssl.

Create a docker network `moodle-network`

```console
docker network create moodle-network
```

Start a `postgres` server instance from the official postgres repository

| If `mysql` is desired, use the 2nd example further below.

```console
docker run --rm -d --name moodle-postgres \
           --network moodle-network \
           --env POSTGRES_USER=moodle \
           --env POSTGRES_PASSWORD=moodle \
           --env POSTGRES_DB=moodle \
           postgres:11.4
```

Then start a `venatorfox/moodle` instance, expose port 80.

```console
docker run --rm -d --name some-moodle \
           --network moodle-network \
           --env MOODLE_WWWROOT=http://localhost \
           --publish 80:80 \
           venatorfox/moodle:3.7.1
```

##### MySQL Variant

Example: Same thing as above, but for mySQL instead of Postgres.
Postgres is however recommended as per [Moodle docs](https://docs.moodle.org/37/en/Arguments_in_favour_of_PostgreSQL). Please note that brand new installs of MySQL 8 will require a [workaround](https://www.google.com/search?rls=en&q=authentication+method+unknown+to+the+client&ie=UTF-8&oe=UTF-8) to avoid authentication issues. Upgrades from MySQL 5 to 8 carries over the workaround.

Create a docker network `moodle-network`

```console
docker network create moodle-network
```

```console
docker run --rm -d --name moodle-mysql \
           --network moodle-network \
           --env MYSQL_ROOT_PASSWORD=moodle \
           --env MYSQL_USER=moodle \
           --env MYSQL_PASSWORD=moodle -env \
           --MYSQL_DATABASE=moodle \
           mysql:5.7.27
```

Then start a `venatorfox/moodle` instance, change dbtype settings, expose port 80.

```console
docker run --rm -d --name some-moodle \
           --network moodle-network \
           --env MOODLE_WWWROOT=http://localhost \
           --env MOODLE_DBTYPE=mysqli \
           --env MOODLE_DBHOST=moodle-mysql \
           --env MOODLE_DBPORT=3306 \
           --publish 80:80 \
           venatorfox/moodle:3.7.1
```

If this is a new db install, grab some covfefe and wait until the webserver starts (indicated by `[services.d] done` in the log).
Visit the site at Visit the site at [http://localhost](http://localhost), default username (if nothing was configured via --env) is "admin" and password "password". #superSecure 

See below for available runtime environment variables for a more specific configuration, such as plugin installation.

Volumes should be mounted for the moodledata and the database for persistant storage. The `moodledata` directory is located at `/var/moodledata`. Please remember to do this so no data loss occurs! The container should be pulled and re-created as version updates from Moodle occur often.

> The Moodle config.php will be created at run and baked into the Moodle Core Install.
> Like all of the other Moodle files, the config.php will be ephemeral, please do not edit it directly.
> Should changes be made, simply destroy the container and run it again with the desired runtime environment variables.

### Runtime Environment Variables

All customizations can be done via the following environment variables. It is recommended to set them properly and not use default values. 
(Unless you want limits at 1M & no SSL, with your admin password being password (Can you not, kthx)).

Ephemeral variables can be changed on existing installations via container rebuild as they are in the moodle container and have no relation to the database.

| Variable | Default Value | Description | Ephemeral |
| ------ | ------ | ------ | ------ |
| NGINX\_MAX\_BODY\_SIZE | 1M | Maximum allowed body size for NGINX | TRUE |
| PHPFPM\_UPLOAD\_MAX\_FILESIZE | 2M | Maximum allowed upload filesize for PHP-FPM | TRUE |
| PHPFPM\_POST\_MAX\_SIZE | 8M | Maximum size of post data allowed for PHP-FPM | TRUE |
| PHPFPM\_MAX\_EXECUTION\_TIME | 30 | Maximum execution time for php scripts | TRUE |
| CRON\_MOODLE\_INTERVAL | 15 | Interval for Moodle Cron in Minutes | TRUE |
| MOODLECFG_SSLPROXY | false | Set to true if an SSL proxy container is put infront of the Moodle install, such as HAProxy with SSL termination; An example will be presented in the below docker compose files | TRUE |
| MOODLECFG_REVERSEPROXY | false | Set to true if the container is accessed via different base URL, This will prevent redirection loop if the container behind a proxy which strips the url | TRUE |
| MOODLE_LANG | en | ------ | FALSE |
| MOODLE_WWWROOT | http://localhost | Be sure to update to https:// if an SSL proxy is used | TRUE |
| MOODLE_DBTYPE | pgsql | Change to `mysqli` if using MySQL | FALSE |
| MOODLE_DBHOST | moodle-postgres | Change to something like `moodle-mysql` if using MySQL | FALSE |
| MOODLE_DBNAME | moodle | ------ | TRUE |
| MOODLE_DBUSER | moodle | ------ | TRUE |
| MOODLE_DBPASS | moodle | ------ | TRUE |
| MOODLE_DBPORT | 5432 | Change to `3306` if using MySQL | TRUE |
| MOODLE_PREFIX | mdl_ | ------ | FALSE |
| MOODLE_FULLNAME | Some Moodle Site Full Name | ------ | FALSE |
| MOODLE_SHORTNAME | Some Moodle Site Short Name | ------ | FALSE |
| MOODLE_SUMMARY | Some Moodle Summary | ------ | FALSE |
| MOODLE_ADMINUSER | admin | ------ | FALSE |
| MOODLE_ADMINPASS | password | ------ | FALSE |
| MOODLE_ADMINEMAIL | admin@example.com | ------ | FALSE |
| INSTALL\_PLUGIN\_URLS | | Enter a list of plugin URLS, seperated by spaces. As URL's often change with new versions hosted by Moodle, it is recommended to download from Moodle and host internally to ensure they stay available. Do NOT change the `basename` of the URL or filename if doing this. | TRUE |

### More Complex Examples
Some more complex (ie. with SSL termination, Plugins, etc...) setup examples are located in the README.md within the [examples directory](https://github.com/Venator-Fox/docker-moodle/tree/master/examples).

### Maintenance

Please [Create an issue](https://github.com/Venator-Fox/docker-moodle/issues) if needed.

