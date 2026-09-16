#!/bin/bash
set -e # We do this to ensure shutdown in case of failure
# 1. We launch mariadb in local, to run initialization commands securely
echo "Launching MariaDB in local mode..."
mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
MYSQL_PID=$!
# 2. We wait for a response to a ping, in a loop, until the service is up
echo "Waiting for MariaDB to be ready..."
until mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; do
    sleep 1
done
echo "MariaDB is ready."

# 3. We execute initialization SQL - Variables come from .env through docker compose
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing mySQL..."
    mysql --socket=/run/mysqld/mysqld.sock << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    echo "Done!"
else
    echo "Database already exists, skipping initialization."
fi
# 4. We turn off the temporary local MariaDB
echo "Turning MariaDB (local) off..."
mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait $MYSQL_PID
echo "Done!"
# 5. Lastly, we launch MariaDB as main process (PID 1)
# exec replaces the bash process for mysql, no fork needed
exec mysqld --user=mysql