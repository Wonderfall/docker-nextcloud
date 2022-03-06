# wonderfall/nextcloud

<p align="center"><a href="https://unsplash.com/photos/9JrBiphz0e0" target="_blank"><img height="128" src="https://raw.githubusercontent.com/wonderfall/docker-nextcloud/main/.github/docker-nextcloud.jpg"></a></p>
<p align="center"><i>The self-hosted productivity platform that keeps you in control.</i></p>

## About
This non-official image is intended as an **all-in-one** (as in monolithic) Nextcloud **production** image. If you're not sure you want this image, you should probably use [the official image](https://hub.docker.com/r/nextcloud). The main goal is to provide a basic image with decent security standards.

Nextcloud [official website](https://nextcloud.com/) and [source code](https://github.com/nextcloud).

___

* [Features](#features)
* [Security](#security)
* [Tags](#tags)
* [Build-time variables](#build-time-variables)
* [Environment variables](#environment-variables)
  * [Runtime](#runtime)
  * [Startup](#startup)
* [Volumes](#volumes)
* [Ports](#ports)
* [Migration](#migration)
* [Usage](#usage)

## Features

- Based on [Alpine Linux](https://alpinelinux.org/).
- Fetching PHP/nginx from their official images.
- **Rootless**: no privilege at any time, even at startup.
- Uses [s6](https://skarnet.org/software/s6/) as a lightweight process supervisor.
- Supports MySQL/MariaDB, PostgresQL and SQLite3 database backends.
- Includes OPCache and APCu for improved caching & performance, also supports redis.
- Tarball integrity & authenticity checked during build process.
- Includes **hardened_malloc**, [a hardened memory allocator](https://github.com/GrapheneOS/hardened_malloc).
- Includes **Snuffleupagus**, [a PHP security module](https://github.com/jvoisin/snuffleupagus).
- Includes a simple **built-in cron** system.
- Much easier to maintain thanks to multi-stages build.
- Does not include imagick, samba, etc. by default.

You're free to make your own image based on this one if you want a specific feature. Uncommon features won't be included as they can increase attack surface: this image intends to stay **minimal**, but **functional enough** to cover basic needs.

## Security

Don't run random images from random dudes on the Internet. Ideally, you want to maintain and build it yourself.

- **Images are scanned every day** by [Trivy](https://github.com/aquasecurity/trivy) for OS vulnerabilities. Known vulnerabilities will be automatically uploaded to [GitHub Security Lab](https://github.com/Wonderfall/docker-nextcloud/security/code-scanning) for full transparency. This also warns me if I have to take action to fix a vulnerability. 
- **Latest tag/version is automatically built weekly**, so you should often update your images regardless if you're already using the latest Nextcloud version.
- **Build production images without cache** (use `docker build --no-cache` for instance) if you want to build your images manually. Latest dependencies will hence be used instead of outdated ones due to a cached layer.
- **A security module for PHP called [Snuffleupagus](https://github.com/jvoisin/snuffleupagus) is used by default**. This module aims at killing entire bug and security exploit classes (including XXE, weak PRNG, file-upload based code execution), thus raising the cost of attacks. For now we're using a configuration file derived from [the default one](https://github.com/jvoisin/snuffleupagus/blob/master/config/default_php8.rules), with some explicit exceptions related to Nextcloud. This configuration file is tested and shouldn't break basic functionality, but it can cause issues in specific and untested use cases: if that happens to you, get logs from either `syslog` or `/nginx/logs/error.log` inside the container, and [open an issue](https://github.com/Wonderfall/docker-nextcloud/issues). You can also disable the security module altogether by changing the `PHP_HARDENING` environment variable to `false` before recreating the container.
- **Images are signed with the GitHub-provided OIDC token in Actions** using the experimental "keyless" signing feature provided by [cosign](https://github.com/sigstore/cosign). You can verify the image signature using `cosign` as well:

```
COSIGN_EXPERIMENTAL=true cosign verify ghcr.io/wonderfall/nextcloud
```

Verifying the signature isn't a requirement, and might not be as seamless as using *Docker Content Trust* (which is not supported by GitHub's OCI registry). However, it's strongly recommended to do so in a sensitive environment to ensure the authenticity of the images and further limit the risk of supply chain attacks.

## Tags

- `latest` : latest Nextcloud version
- `x` : latest Nextcloud x.x (e.g. `23`)
- `x.x.x` : Nextcloud x.x.x (e.g. `23.0.2`)

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
| **CONFIG_NATIVE**           | native code for hmalloc    |
| **UID**                     | user id (default: 1000)    |
| **GID**                     | group id (default: 1000)   |

For convenience they were put at [the very top of the Dockerfile](https://github.com/Wonderfall/docker-nextcloud/blob/main/Dockerfile#L1-L13) and their usage should be quite explicit if you intend to build this image yourself.

## Environment variables

### Runtime

|          Variable         |         Description         |       Default      |
| ------------------------- | --------------------------- | ------------------ |
|     **UPLOAD_MAX_SIZE**   | file upload maximum size    |         10G        |
|      **APC_SHM_SIZE**     | apc shared memory size      |         128M       |
|      **MEMORY_LIMIT**     | max php command mem usage   |         512M       |
|       **CRON_PERIOD**     | cron time interval (min.)   |         5m         |
|   **CRON_MEMORY_LIMIT**   | cron max memory usage       |         1G         |
|         **DB_TYPE**       | sqlite3, mysql, pgsql       |       sqlite3      |
|         **DOMAIN**        | host domain                 |       localhost    |
|      **PHP_HARDENING**    | enables snuffleupagus       |        true        |

Leave them at default if you're not sure what you're doing.

### Startup

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

The usage of [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) will be considered in the future, but `config.php` already covers quite a lot.

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
| **8888** (tcp)               |       Nextcloud web        |

A reverse proxy like [Traefik](https://doc.traefik.io/traefik/) or [Caddy](https://caddyserver.com/) can be used, and you should consider:
- Redirecting all HTTP traffic to HTTPS
- Setting the [HSTS header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) correctly

## Migration

From now on you'll need to make sure all volumes have proper permissions. The default UID/GID is now 1000, so you'll need to build the image yourself if you want to change that, or you can just change the actual permissions of the volumes using `chown -R 1000:1000`. The flexibility provided by the legacy image came at some cost (performance & security), therefore this feature won't be provided anymore.

Other changes that should be reflected in your configuration files:
- `/config` volume is now `/nextcloud/config`
- `/apps2` volume is now `/nextcloud/apps2`
- `ghcr.io/wonderfall/nextcloud` is the new image location

You should edit your `docker-compose.yml` and `config.php` accordingly.

## Usage

*To do.*
