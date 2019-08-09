[![](https://images.microbadger.com/badges/version/venatorfox/moodle:3.7.1.svg)](http://git.moodle.org/gw?p=moodle.git;a=tree;hb=refs/heads/MOODLE_34_STABLE "MOODLE_34_STABLE (3.7.1+)") [![](https://images.microbadger.com/badges/image/venatorfox/moodle:3.7.1.svg)](https://microbadger.com/images/venatorfox/moodle "View image metadata on MicroBadger") [![Pulls on Docker Hub](https://img.shields.io/docker/pulls/venatorfox/moodle.svg)](https://hub.docker.com/r/venatorfox/moodle)  [![Stars on Docker Hub](https://img.shields.io/docker/stars/venatorfox/moodle.svg)](https://hub.docker.com/r/venatorfox/moodle) [![GitHub Open Issues](https://img.shields.io/github/issues/Venator-Fox/docker-moodle.svg)](https://github.com/Venator-Fox/docker-moodle/issues) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

### Examples

This directory contains some example files in order to run the [venatorfox/moodle](https://hub.docker.com/r/venatorfox/moodle/) in a more complex manner. (ie. with SSL termination, HAProxy, etc...) These examples assume this is installed in a non-orchestrated manner on a host.

The following examples are provided here:   
- HAProxy SSL Termination, Self Signed SSL, and common configurations via docker-compose (for development)  
- HAProxy SSL Termination, Let's Encrypt CA, and common configurations via systemd (for production)

#### HAProxy SSL Termination, and common configurations via docker-compose  
> This is recommended for testing. Compose is not recommended for production.

This example will run HAProxy with snakeoil SSL termination for https://localhost.

You will need the `haproxy.cfg` and `docker-compose.yml` files from the examples directory.

An entry to the hosts file can be added to whatever for testing. HAProxy will handle SSL.
Be sure to adjust the HOST environment variable below for whatever localhost self-signed certificate desired.
Of course in production use a real CA, like LetsEncrypt.

Note that running this compose file will create files in `/srv/docker/volumes/` on your host.
You can remove this after toying with the example.

Run the following to generate a quick self-signed SSL certificate:

~~~
mkdir -p /srv/docker/volumes/moodle-haproxy/ssl/
docker run --rm -v /srv/docker/volumes/moodle-haproxy/ssl/:/ssl/ -e HOST=localhost -e TYPE=pem project42/selfsignedcert
~~~

Copy the `haproxy.cfg` from the examples directory to `/srv/docker/volumes/moodle-haproxy/haproxy`

Compose version in this example is v3.5  
Run `docker-compose -f docker-compose.yml up` to bring the stack up with your variables.
After install, visit [https://localhost](https://localhost).  
Use `docker-compose -f docker-compose.yml down` to destroy all containers.

#### HAProxy SSL Termination, and common configurations via systemd  
> This is recommended for production for non-orchestrated installs. These unit files will start containers systemd. If you have no SSL certificate please look into LetsEncrypt CA. A good containerized deployment by linuxserver is located here: [linuxserver/letsencrypt](https://hub.docker.com/r/linuxserver/letsencrypt/)

Note that running these will create files in `/srv/docker/volumes/` on your host. Use these example files to your preference. Some examples are below, tested with CentOS/RHEL

> Method 1 (Copy to local config dir `/etc/systemd/system/`)
>
~~~
cp -rfv /some/location/docker-moodle/examples/systemd/*.service /etc/systemd/system/
~~~

or

> Method 2 (Symlink to vendor/pkg dir `/usr/lib/systemd/system/`) (use full paths)
>
```console
ln -s /some/location/docker-moodle/examples/systemd/moodle-haproxy.service /usr/lib/systemd/system/
ln -s /some/location/docker-moodle/examples/systemd/moodle-postgres.service /usr/lib/systemd/system/
ln -s /some/location/docker-moodle/examples/systemd/some-moodle.service /usr/lib/systemd/system/
```

or

> Method 3 (Use the unit files directly)
>
```console
systemctl start /some/location/docker-moodle/examples/systemd/moodle-haproxy.service
```

Create persistant directory `ssl` for `moodle-haproxy`

~~~
mkdir -p /srv/docker/volumes/moodle-haproxy/haproxy/ssl
~~~

Copy the `haproxy.cfg` from the examples directory to `/srv/docker/volumes/moodle-haproxy/haproxy/`

~~~
cp -v /some/location/docker-moodle/examples/haproxy/haproxy.cfg /srv/docker/volumes/moodle-haproxy/haproxy/
~~~

Create a network. 

~~~
docker network create moodle-network
~~~

Enable and start `moodle-haproxy`, this will bring up the rest of the containers

~~~
systemctl enable --now moodle-haproxy
~~~

Verify:

~~~
systemctl status moodle-haproxy

● moodle-haproxy.service - Moodle HAProxy Container (moodle-haproxy)
   Loaded: loaded (/etc/systemd/system/moodle-haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2019-07-10 15:50:25 CDT; 21s ago
~~~

~~~
docker ps -a

CONTAINER ID        IMAGE                      COMMAND                  CREATED              STATUS              PORTS                                      NAMES
20a6024c0f85        million12/haproxy:latest   "/bootstrap.sh"          About a minute ago   Up About a minute   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   moodle-haproxy
525d546798f1        venatorfox/moodle:3.7.4    "/init"                  About a minute ago   Up About a minute                                              some-moodle
993f8766dcf2        postgres:11.4              "docker-entrypoint.s…"   About a minute ago   Up About a minute   5432/tcp                                   moodle-postgres
~~~

##### Other Notes

When translating docker run into systemd unit files, be sure to use `systemd-escape` when needed. (ie spaces or special characters):

~~~
systemd-escape 'Something with spaces'
Something\x20with\x20spaces\x21
~~~

For Example:

~~~
docker run --name some-moodle \
           --network moodle-network \
           --env MOODLE_WWWROOT=https://localhost \
           --env NGINX_MAX_BODY_SIZE=64M \
           --env PHPFPM_UPLOAD_MAX_FILESIZE=64M \
           --env PHPFPM_POST_MAX_SIZE=64M \
           --env MOODLE_FULLNAME=Some Full Organization Name \
           --publish 80:80 venatorfox/moodle:3.7.1
~~~

Would look like this in a unit file

~~~
ExecStart=/usr/bin/docker run --name some-moodle \
                              --network moodle-network \
                              --env MOODLE_WWWROOT=http://localhost \
                              --env NGINX_MAX_BODY_SIZE=64M \
                              --env PHPFPM_UPLOAD_MAX_FILESIZE=64M \
                              --env PHPFPM_POST_MAX_SIZE=64M \
                              --env MOODLE_FULLNAME=Some\x20Full\x20Organization\x20Name \
                              --publish 80:80 venatorfox/moodle:3.7.1
~~~

