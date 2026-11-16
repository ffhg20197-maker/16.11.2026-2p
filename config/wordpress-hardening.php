<?php
// Merge these settings into the existing wp-config.php; do not overwrite it.
define('DISALLOW_FILE_EDIT', true);
define('FORCE_SSL_ADMIN', true);
define('WP_AUTO_UPDATE_CORE', true);
define('WP_DEBUG', false);
define('WP_DEBUG_DISPLAY', false);
define('WP_DEBUG_LOG', false);
define('AUTOSAVE_INTERVAL', 120);
define('EMPTY_TRASH_DAYS', 14);
// Generate unique AUTH_KEY, SECURE_AUTH_KEY, LOGGED_IN_KEY, NONCE_KEY
// and corresponding salts using https://api.wordpress.org/secret-key/1.1/salt/
// Example only: $table_prefix = 'sec26_'; migrate table names before changing it.
