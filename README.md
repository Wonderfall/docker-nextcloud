# wonderfall/nextcloud
*The self-hosted productivity platform that keeps you in control.*

Nextcloud [official website](https://nextcloud.com/) and [source code](https://github.com/nextcloud).

## Why this image?
This non-official image is intended as an **all-in-one** (as in monolithic) Nextcloud **production** image. If you're not sure you want this image, you should probably use [the official image](https://hub.docker.com/r/nextcloud).

## Security
Don't run random images from random dudes on the Internet. Ideally, you want to maintain and build it yourself.

Images are scanned every day by [Trivy](https://github.com/aquasecurity/trivy) for OS vulnerabilities. They are rebuilt once a week, so you should often update your images regardless of your Nextcloud version.

## Features
- Fetching PHP/nginx from their official images.
- Does not use any privilege at any time, even at startup.
- Much easier to maintain thanks to multi-stages build.
- Includes hardened_malloc, a hardened memory allocator.
- Does not include imagick, samba, etc. by default.

## Tags
- `latest` : latest Nextcloud version
- `x` : latest Nextcloud x.x (e.g. `21`)
- `x.x.x` : Nextcloud x.x.x (e.g. `21.0.2`)

You can always have a glance [here](https://github.com/users/Wonderfall/packages/container/package/nextcloud).
Only the **latest stable version** will be maintained by myself.

## Build-time variables
|          Variable           |         Description        |
| --------------------------- | -------------------------- |
| **NEXTCLOUD_VERSION**       | version of Nextcloud       |
| **ALPINE_VERSION**          | version of Alpine Linux    |
| **PHP_VERSION**             | version of PHP             |
| **NGINX_VERSION**           | version of nginx           |
| **APCU_VERSION**            | version of APCu (php ext)  |
| **REDIS_VERSION**           | version of redis (php ext) |
| **HARDENED_MALLOC_VERSION** | version of hardened_malloc |
| **UID**                     | user id (default: 1000)    |
| **GID**                     | group id (default: 1000)   |

For convenience they were put at the very of the Dockerfile and their usage should be quite explicit if you intend to build this image yourself.

## Environment variables (Dockerfile)

|          Variable         |         Description         |       Default      |
| ------------------------- | --------------------------- | ------------------ |
|     **UPLOAD_MAX_SIZE**   | file upload maximum size    |         10G        |
|      **APC_SHM_SIZE**     | apc shared memory size      |         128M       |
|      **MEMORY_LIMIT**     | max php command mem usage   |         512M       |
|       **CRON_PERIOD**     | cron time interval (min.)   |         5m         |
|   **CRON_MEMORY_LIMIT**   | cron max memory usage       |         1G         |
|         **DB_TYPE**       | sqlite3, mysql, pgsql       |       sqlite3      |
|         **DOMAIN**        | host domain                 |       localhost    |

Leave them at default if you're not sure what you're doing.

## Environment variables (used by setup.sh)

|          Variable         |         Description         | 
| ------------------------- | --------------------------- |
|        **ADMIN_USER**     | admin username              |
|      **ADMIN_PASSWORD**   | admin password              |
|         **DB_TYPE**       | sqlit3, mysql, pgsql        |
|         **DB_NAME**       | name of the database        |
|         **DB_USER**       | name of the database user   |
|       **DB_PASSWORD**     | password of the db user     |
|         **DB_HOST**       | database host               |

`ADMIN_USER` and `ADMIN_PASSWORD` are optional and mainly for niche purposes. Obviously, avoid clear text passwords. Once `setup.sh` has run for the first time, these variables can be removed. You should then edit `/nextcloud/config/config.php` directly if you want to change something in your configuration.

## Volumes
|          Variable            |         Description        |
| -------------------------    | -------------------------- |
| **/data**                    |         data files         |
| **/nextcloud/config**        |        config files        |
| **/nextcloud/apps2**         |       3rd-party apps       |
| **/nextcloud/themes**        |        custom themes       |

## Ports
|              Port            |            Use             |
| -------------------------    | -------------------------- |
| **8888**                     |       Nextcloud web        |


A reverse proxy like Traefik/Caddy should be used.

## Migration from the legacy image
From now on you'll need to make sure all volumes have proper permissions. The default UID/GID is now 1000, so you'll need to build the image yourself if you want to change that, or you can just change the actual permissions of the volumes using `chown -R 1000:1000`. The flexibility provided by the legacy image came at some cost (performance & security), therefore this feature won't be provided anymore.

Other changes that should be reflected in your configuration files:
- `/config` volume is now `/nextcloud/config`
- `/apps2` volume is now `/nextcloud/apps2`
- `ghcr.io/wonderfall/nextcloud` is the new image location

You should edit your `docker-compose.yml` and `config.php` accordingly.

## Get started
*To do.*
