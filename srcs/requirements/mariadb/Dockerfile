FROM debian:bookworm
# We update the packet manager and install mariadb-server
RUN apt-get update && apt-get install -y mariadb-server
# We copy the mariadb.conf file to the conf file stored in Docker
COPY conf/mariadb.conf /etc/mysql/mariadb.conf.d/50-server.cnf
# We copy the script into a conf file
COPY ./tools/mariadb.sh /usr/local/bin/
# We create a directory to store configurations like pid and socket
RUN mkdir -p /var/run/mysqld && chown -R mysql:mysql /var/run/mysqld && chmod 775 /var/run/mysqld && chmod +x /usr/local/bin/mariadb.sh
# We open the port 3306 for conections
EXPOSE 3306
# We run a mariadb exclusive install command, working based on the .conf
RUN mariadb-install-db
# After all is built, the sh file will be the first thing executed on startup
ENTRYPOINT [ "/usr/local/bin/mariadb.sh" ]