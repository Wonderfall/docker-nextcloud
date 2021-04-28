#!/bin/sh

CONFIGFILE=/nextcloud/config/config.php

# Create an initial configuration file.
instanceid=oc$(openssl rand -hex 6 | head -c 10)

cat > $CONFIGFILE <<EOF;
<?php
\$CONFIG = array (
  'datadirectory' => '/data',

  "apps_paths" => array (
      0 => array (
              "path"     => "/nextcloud/apps",
              "url"      => "/apps",
              "writable" => false,
      ),
      1 => array (
              "path"     => "/nextcloud/apps2",
              "url"      => "/apps2",
              "writable" => true,
      ),
  ),

  'memcache.local' => '\OC\Memcache\APCu',

  'instanceid' => '$instanceid',
);
?>
EOF

# Create an auto-configuration file to fill in database settings
adminpassword=$(dd if=/dev/urandom bs=1 count=40 2>/dev/null | sha1sum | fold -w 30 | head -n 1)
cat > /nextcloud/config/autoconfig.php <<EOF;
<?php
\$AUTOCONFIG = array (
  # storage/database
  'directory'     => '/data',
  'dbtype'        => '${DB_TYPE:-sqlite3}',
  'dbname'        => '${DB_NAME:-nextcloud}',
  'dbuser'        => '${DB_USER:-nextcloud}',
  'dbpass'        => '${DB_PASSWORD:-password}',
  'dbhost'        => '${DB_HOST:-nextcloud-db}',
  'dbtableprefix' => 'oc_',
EOF
if [[ ! -z "$ADMIN_USER"  ]]; then
  cat >> /nextcloud/config/autoconfig.php <<EOF;
  'adminlogin'    => '${ADMIN_USER}',
  'adminpass'     => '${ADMIN_PASSWORD}',
EOF
fi
cat >> /nextcloud/config/autoconfig.php <<EOF;
);
?>
EOF

echo "Starting automatic configuration..."
# Execute setup
(cd /nextcloud; php index.php &>/dev/null)
echo "Automatic configuration finished."

# Update config.php
CONFIG_TEMP=$(/bin/mktemp)
php <<EOF > $CONFIG_TEMP && mv $CONFIG_TEMP $CONFIGFILE
<?php
include($CONFIGFILE);

//\$CONFIG['memcache.local'] = '\\OC\\Memcache\\Memcached';
\$CONFIG['mail_from_address'] = 'administrator'; # just the local part, matches our master administrator address

\$CONFIG['logtimezone'] = '$TZ';
\$CONFIG['logdateformat'] = 'Y-m-d H:i:s';

echo "<?php\n\\\$CONFIG = ";
var_export(\$CONFIG);
echo ";";
?>
EOF

sed -i "s/localhost/$DOMAIN/g" $CONFIGFILE

# Setup is finished, no need for first run wizard
if [[ ! -z "$ADMIN_USER"  ]]; then
  occ app:disable firstrunwizard
fi
