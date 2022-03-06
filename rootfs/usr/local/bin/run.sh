#!/bin/sh

# Apply environment variables settings
sed -i -e "s/<APC_SHM_SIZE>/$APC_SHM_SIZE/g" /usr/local/etc/php/conf.d/apcu.ini \
       -e "s/<OPCACHE_MEM_SIZE>/$OPCACHE_MEM_SIZE/g" /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
       -e "s/<CRON_MEMORY_LIMIT>/$CRON_MEMORY_LIMIT/g" /etc/s6.d/cron/run \
       -e "s/<CRON_PERIOD>/$CRON_PERIOD/g" /etc/s6.d/cron/run \
       -e "s/<MEMORY_LIMIT>/$MEMORY_LIMIT/g" /usr/local/bin/occ \
       -e "s/<UPLOAD_MAX_SIZE>/$UPLOAD_MAX_SIZE/g" /etc/nginx/nginx.conf /usr/local/etc/php-fpm.conf \
       -e "s/<MEMORY_LIMIT>/$MEMORY_LIMIT/g" /usr/local/etc/php-fpm.conf

# Enable Snuffleupagus
if [ "$PHP_HARDENING" == "true" ] && [ ! -f /usr/local/etc/php/conf.d/snuffleupagus.ini ]; then
    echo "Enabling Snuffleupagus..."
    cp /usr/local/etc/php/snuffleupagus/* /usr/local/etc/php/conf.d
fi

# If new install, run setup
if [ ! -f /nextcloud/config/config.php ]; then
    touch /nextcloud/config/CAN_INSTALL
    /usr/local/bin/setup.sh
else
    occ upgrade
fi

# Run processes
exec /bin/s6-svscan /etc/s6.d
