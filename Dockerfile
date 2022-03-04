# -------------- Build-time variables --------------
ARG NEXTCLOUD_VERSION=23.0.2
ARG PHP_VERSION=8.0
ARG NGINX_VERSION=1.20

ARG ALPINE_VERSION=3.15
ARG HARDENED_MALLOC_VERSION=11

ARG UID=1000
ARG GID=1000
# ---------------------------------------------------

### Build PHP base
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} as base

RUN apk -U upgrade \
 && apk add -t build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        gmp-dev \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        openldap-dev \
        postgresql-dev \
        zlib-dev \
 && apk --no-cache add \
        freetype \
        gmp \
        icu \
        libjpeg-turbo \
        libpq \
        libpq \
        libwebp \
        libzip \
        openldap \
        zlib \
 && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-configure ldap \
 && docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        ldap \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gmp \
 && pecl install APCu \
 && pecl install redis \
 && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini \
 && apk del build-deps \
 && rm -rf /var/cache/apk/*


### Build Hardened Malloc
ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as build-malloc

ARG HARDENED_MALLOC_VERSION
ARG CONFIG_NATIVE=false
ARG VARIANT=light

RUN apk --no-cache add build-base git gnupg && cd /tmp \
 && wget -q https://github.com/thestinger.gpg && gpg --import thestinger.gpg \
 && git clone --depth 1 --branch ${HARDENED_MALLOC_VERSION} https://github.com/GrapheneOS/hardened_malloc \
 && cd hardened_malloc && git verify-tag $(git describe --tags) \
 && make CONFIG_NATIVE=${CONFIG_NATIVE} VARIANT=${VARIANT}


### Fetch nginx
FROM nginx:${NGINX_VERSION}-alpine as nginx


### Build Nextcloud (production environemnt)
FROM base as nextcloud

COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx /etc/nginx /etc/nginx
COPY --from=build-malloc /tmp/hardened_malloc/out-light/libhardened_malloc-light.so /usr/local/lib/

ARG NEXTCLOUD_VERSION
ARG GPG_nextcloud="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"

ARG UID
ARG GID

ENV UPLOAD_MAX_SIZE=10G \
    APC_SHM_SIZE=128M \
    OPCACHE_MEM_SIZE=128 \
    MEMORY_LIMIT=512M \
    CRON_PERIOD=5m \
    CRON_MEMORY_LIMIT=1g \
    DB_TYPE=sqlite3 \
    DOMAIN=localhost \
    LD_PRELOAD="/usr/local/lib/libhardened_malloc-light.so /usr/lib/preloadable_libiconv.so"

RUN apk --no-cache add \
        gnupg \
        gnu-libiconv \
        pcre \
        s6 \
 && NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" && cd /tmp \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha512 \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc \
 && wget -q https://nextcloud.com/nextcloud.asc \
 && echo "Verifying both integrity and authenticity of ${NEXTCLOUD_TARBALL}..." \
 && CHECKSUM_STATE=$(echo -n $(sha512sum -c ${NEXTCLOUD_TARBALL}.sha512) | tail -c 2) \
 && if [ "${CHECKSUM_STATE}" != "OK" ]; then echo "Error: checksum does not match" && exit 1; fi \
 && gpg --import nextcloud.asc \
 && FINGERPRINT="$(LANG=C gpg --verify ${NEXTCLOUD_TARBALL}.asc ${NEXTCLOUD_TARBALL} 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Error: invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_nextcloud}" ]; then echo "Error: wrong GPG fingerprint" && exit 1; fi \
 && echo "All seems good, now unpacking ${NEXTCLOUD_TARBALL}..." \
 && mkdir /nextcloud && tar xjf ${NEXTCLOUD_TARBALL} --strip 1 -C /nextcloud \
 && apk del gnupg && rm -rf /tmp/* /root/.gnupg \
 && adduser -g ${GID} -u ${UID} --disabled-password --gecos "" nextcloud \
 && chown -R nextcloud:nextcloud /nextcloud

COPY --chown=nextcloud:nextcloud rootfs /

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/*

USER nextcloud

WORKDIR /nextcloud

VOLUME /data /nextcloud/config /nextcloud/apps2 /nextcloud/themes

EXPOSE 8888

LABEL description="A server software for creating file hosting services" \
      nextcloud="Nextcloud v${NEXTCLOUD_VERSION}" \
      maintainer="Wonderfall <wonderfall@targaryen.house>"

CMD ["run.sh"]
