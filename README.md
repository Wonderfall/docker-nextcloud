## wonderfall/nextcloud


[![](https://images.microbadger.com/badges/version/wonderfall/nextcloud.svg)](http://microbadger.com/images/wonderfall/nextcloud "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/wonderfall/nextcloud.svg)](http://microbadger.com/images/wonderfall/nextcloud "Get your own image badge on microbadger.com")

**Made for my own use. Irregular updates! This image is eventually intended as a base for your own Docker image. I cannot be responsible if you're using outdated Docker images.**

___
⚠️**DEPRECATED**: don't worry, I'll keep maintaing it for a while. This image was made years ago and needs some rework:
- For instance it uses `su-exec` to degrade privileges, which is fine as an attempt to get a *rootless running* image, but more secure ways to make sure *root* is never used should be preferred.
- As a consequence to that, a newer image should drop all the `chown` instructions at startup time: no more seconds of waiting, even minutes if you're using overlayfs as the storage driver (which is Docker's default). This was fine for flexibility, but users should really learn how to manage the permissions of their volumes.
- I made a base image (`wonderfall/nginx-php`) years ago when I estimated that the PHP packages from Alpine Linux were not reliable for this. I think this is no longer a requirement, and it's a pain to maintain two images instead of just one.

As I said, I'll keep "maintaining" it for now (I always thought of my images as being bases for your own images, really __don't run Docker images from random dudes__ like me from the Internet), but I'll eventually make a brand new image sometime soon. Meaning, you should be prepared to maintain or make your own image, or use the official one which is fine and regularly updated now.

Above all, take care and take security seriously. Thanks to everyone reading this!
___

⚠️ **HSTS is not enforced anymore as of 25/03/21:** please consider configuring your reverse proxy proprerly to do that. It didn't make sens in the first place to enforce my settings (which were outdated anyway), and I'm sorry for that. Also if you don't know what HSTS settings are right for you, I strongly advise reading [this](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security).

### Features
- Based on Alpine Linux.
- Bundled with nginx and PHP 8.0 (wonderfall/nginx-php image).
- Automatic installation using environment variables.
- Package integrity (SHA512) and authenticity (PGP) checked during building process.
- Data and apps persistence.
- OPCache (opcocde), APCu (local) installed and configured.
- system cron task running.
- MySQL, PostgreSQL (server not built-in) and sqlite3 support.
- Redis, FTP, SMB, LDAP, IMAP support.
- GNU Libiconv for php iconv extension (avoiding errors with some apps).
- No **running** root processes **except on start** (reducing privileges afterwards).
- Environment variables provided (see below).

### Security
As many images from the time it was first made, this image follows the principle of degrading privileges. It runs first as root to ensure permissions are set correctly and then only makes use of the UID/GID of your choice. While I agree it's not perfect (due to Linux insecurity), it seemed the best security/comfort balance at the time and it'll remain so for a while.

### Tags
- **latest** : latest stable version.
- **21.0** : latest 21.0.x version (stable, recommended)
- **20.0** : latest 20.0.x version (old stable)

Since this project should suit my needs, I'll only maintain the latest stable version available.

### Build-time variables
- **NEXTCLOUD_VERSION** : version of nextcloud
- **GPG_nextcloud** : signing key fingerprint

### Environment variables
- **UID** : nextcloud user id *(default : 991)*
- **GID** : nextcloud group id *(default : 991)*
- **UPLOAD_MAX_SIZE** : maximum upload size *(default : 10G)*
- **APC_SHM_SIZE** : apc memory size *(default : 128M)*
- **OPCACHE_MEM_SIZE** : opcache memory size in megabytes *(default : 128)*
- **MEMORY_LIMIT** : php memory limit *(default : 512M)*
- **CRON_PERIOD** : time interval between two cron tasks *(default : 15m)*
- **CRON_MEMORY_LIMIT** : memory limit for PHP when executing cronjobs *(default : 1024m)*
- **TZ** : the system/log timezone *(default : Etc/UTC)*
- **ADMIN_USER** : username of the admin account *(default : none, web configuration)*
- **ADMIN_PASSWORD** : password of the admin account *(default : none, web configuration)*
- **DOMAIN** : domain to use during the setup *(default : localhost)*
- **DB_TYPE** : database type (sqlite3, mysql or pgsql) *(default : sqlite3)*
- **DB_NAME** : name of database *(default : none)*
- **DB_USER** : username for database *(default : none)*
- **DB_PASSWORD** : password for database user *(default : none)*
- **DB_HOST** : database host *(default : none)*

Don't forget to use a **strong password** for the admin account!

### Port
- **8888** : HTTP Nextcloud port.

### Volumes
- **/data** : Nextcloud data.
- **/config** : config.php location.
- **/apps2** : Nextcloud downloaded apps.
- **/nextcloud/themes** : Nextcloud themes location.
- **/php/session** : php session files.

### Database
Basically, you can use a database instance running on the host or any other machine. An easier solution is to use an external database container. I suggest you to use MariaDB, which is a reliable database server. You can use the official `mariadb` image available on Docker Hub to create a database container, which must be linked to the Nextcloud container. PostgreSQL can also be used as well.

### Setup
Pull the image and create a container. `/docker` can be anywhere on your host, this is just an example. Change `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` values (mariadb). You may also want to change UID and GID for Nextcloud, as well as other variables (see *Environment Variables*).

```
docker pull wonderfall/nextcloud && docker pull mariadb

docker run -d --name db_nextcloud \
       -v /docker/nextcloud/db:/var/lib/mysql \
       -e MYSQL_ROOT_PASSWORD=supersecretpassword \
       -e MYSQL_DATABASE=nextcloud -e MYSQL_USER=nextcloud \
       -e MYSQL_PASSWORD=supersecretpassword \
       mariadb:10
       
docker run -d --name nextcloud \
       --link db_nextcloud:db_nextcloud \
       -v /docker/nextcloud/data:/data \
       -v /docker/nextcloud/config:/config \
       -v /docker/nextcloud/apps:/apps2 \
       -v /docker/nextcloud/themes:/nextcloud/themes \
       -e UID=1000 -e GID=1000 \
       -e UPLOAD_MAX_SIZE=10G \
       -e APC_SHM_SIZE=128M \
       -e OPCACHE_MEM_SIZE=128 \
       -e CRON_PERIOD=15m \
       -e TZ=Etc/UTC \
       -e ADMIN_USER=mrrobot \
       -e ADMIN_PASSWORD=supercomplicatedpassword \
       -e DOMAIN=cloud.example.com \
       -e DB_TYPE=mysql \
       -e DB_NAME=nextcloud \
       -e DB_USER=nextcloud \
       -e DB_PASSWORD=supersecretpassword \
       -e DB_HOST=db_nextcloud \
       wonderfall/nextcloud
```

You are **not obliged** to use `ADMIN_USER` and `ADMIN_PASSWORD`. If these variables are not provided, you'll be able to configure your admin acccount from your browser.

### Configure
In the admin panel, you should switch from `AJAX cron` to `cron` (system cron).

### Update
Pull a newer image, then recreate the container as you did before (*Setup* step). None of your data will be lost since you're using external volumes. If Nextcloud performed a full upgrade, your apps could be disabled, enable them again **(starting with 12.0.x, your apps are automatically enabled after an upgrade)**.

### Docker-compose
I advise you to use [docker-compose](https://docs.docker.com/compose/), which is a great tool for managing containers. You can create a `docker-compose.yml` with the following content (which must be adapted to your needs) and then run `docker-compose up -d nextcloud-db`, wait some 15 seconds for the database to come up, then run everything with `docker-compose up -d`, that's it! On subsequent runs,  a single `docker-compose up -d` is sufficient!

#### Docker-compose file
Don't copy/paste without thinking! It is a model so you can see how to do it correctly.

```
version: '3'

networks:
  nextcloud_network:
    external: false

services:
  nextcloud:
    image: wonderfall/nextcloud
    depends_on:
      - nextcloud-db           # If using MySQL
      - redis                  # If using Redis
    environment:
      - UID=1000
      - GID=1000
      - UPLOAD_MAX_SIZE=10G
      - APC_SHM_SIZE=128M
      - OPCACHE_MEM_SIZE=128
      - CRON_PERIOD=15m
      - TZ=Europe/Berlin
      - DOMAIN=localhost
      - DB_TYPE=mysql
      - DB_NAME=nextcloud
      - DB_USER=nextcloud
      - DB_PASSWORD=supersecretpassword
      - DB_HOST=nextcloud-db
    volumes:
      - /docker/nextcloud/data:/data
      - /docker/nextcloud/config:/config
      - /docker/nextcloud/apps:/apps2
      - /docker/nextcloud/themes:/nextcloud/themes
    networks:
      - nextcloud_network

  # If using MySQL
  nextcloud-db:
    image: mariadb
    volumes:
      - /docker/nextcloud/db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=supersecretpassword
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=supersecretpassword
    networks:
      - nextcloud_network
    
  # If using Redis
  redis:
    image: redis:alpine
    container_name: redis
    volumes:
      - /docker/nextcloud/redis:/data
    networks:
      - nextcloud_network
```

You can update everything with `docker-compose pull` followed by `docker-compose up -d`.

### How to configure Redis
Redis can be used for distributed and file locking cache, alongside with APCu (local cache), thus making Nextcloud even more faster. As PHP redis extension is already included, all you have to is to deploy a redis server (you can do as above with docker-compose) and bind it to nextcloud in your config.php file :

```
'memcache.distributed' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\APCu',
'redis' => array(
   'host' => 'redis',
   'port' => 6379,
   ),
```

### Tip : how to use occ command
There is a script for that, so you shouldn't bother to log into the container, set the right permissions, and so on. Just use `docker exec -ti nexcloud occ command`.
