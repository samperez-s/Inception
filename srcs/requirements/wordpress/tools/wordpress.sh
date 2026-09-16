#!/bin/bash
set -e

# 1. Wait for MariaDB to be ready before doing anything
echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    sleep 1
done
echo "MariaDB is ready."

# 2. Download and configure WordPress if not already done
if [ ! -f "/var/www/wordpress/wp-config.php" ]; then
    echo "Setting up WordPress..."

    # Download WordPress core files
    wp core download --path=/var/www/wordpress --allow-root

    # Create wp-config.php using environment variables
    wp config create \
        --path=/var/www/wordpress \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    # Install WordPress
    wp core install \
        --path=/var/www/wordpress \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    # Create a second regular user (subject requires two users)
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --path=/var/www/wordpress \
        --allow-root

    echo "WordPress setup complete."
else
    echo "WordPress already configured, skipping setup."
fi

# 3. Start php-fpm in foreground as PID 1
# php-fpmX.X path depends on the PHP version installed
echo "Starting php-fpm..."
exec php-fpm8.2 -F