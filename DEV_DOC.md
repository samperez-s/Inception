_This project has been created as part of the 42 curriculum by samperez_

# Inception - DEV_DOC
The purpose of this document, is to illustrate how a developer can:
- Set up the environment from scratch (prerequisites, configuration files, secrets).
- Build and launch the project using the Makefile and Docker Compose.
- Use relevant commands to manage the containers and volumes.
- Identify where the project data is stored and how it persists.

## Initial Setup
After succesfully creating the virtual machine, the first thing I did was create a shared folder inside VirtualBoxVM's interface, specifying the mount route and making sure the folder was marked as _Auto-Mount_ and _Make Permanent_

After that, I began by creating the directory structure, which is shown in the subject.
## Project Structure:

```
Inception_SF/
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
└── srcs/
	├── docker-compose.yml
	├── .env
	└── requirements/
		├── mariadb/
		│   ├── Dockerfile
		│   ├── .dockerignore
		│   ├── conf/
		│   └── tools/
		├── nginx/
		│   ├── Dockerfile
		│   ├── .dockerignore
		│   ├── conf/
		│   └── tools/
		└── wordpress/
			├── Dockerfile
			├── .dockerignore
			├── conf/
			└── tools/
```


Then, I decided to start by configuring mariadb, and later configure nginx and wordpress

## MariaDB setup
### Directory structure:
```
mariadb/
	├── Dockerfile
	├── .dockerignore
	├── conf/
	│   └── mariadb.conf
	└── tools/
		└── mariadb.sh
```

I started with the Dockerfile and the mariadb.conf

### Dockerfile
The Dockerfile installs MariaDB on a Debian Bookworm base image, copies the custom configuration file, creates the runtime directory that MariaDB needs for its socket and PID file, and runs `mariadb-install-db` at build time to initialize the base system tables. The actual database, user, and credentials are created at runtime by the entrypoint script, since those values come from environment variables.

### mariadb.conf
The configuration file replaces the default `50-server.cnf`.  
The most important setting is `bind-address = 0.0.0.0`, which allows MariaDB to accept connections from other containers on the Docker network. Without this, it would only listen on localhost and WordPress would not be able to reach it.

### mariadb.sh
The entrypoint script runs in five steps:
1. Starts MariaDB temporarily in local mode (`--skip-networking`) so no external connections are possible during initialization.
2. Waits for MariaDB to be ready by polling with `mysqladmin ping`.
3. Creates the WordPress database, the WordPress user with its password, and sets the root password — all values read from environment variables.
4. Shuts down the temporary MariaDB instance cleanly.
5. Replaces itself with `mysqld` via `exec`, making it PID 1 so Docker can manage its lifecycle correctly.

## WordPress setup
### Directory structure:
```
wordpress/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── www.conf
└── tools/
    └── wordpress.sh
```

### Dockerfile
The Dockerfile installs php-fpm, php-mysql, curl and mariadb-client on a Debian Bookworm base image. It then downloads WP-CLI — a command line tool for managing WordPress — and installs it at `/usr/local/bin/wp`. The `www.conf` configuration file is copied to override php-fpm's default socket behaviour, and the entrypoint script is copied and made executable.

### www.conf
Overrides php-fpm's default configuration. The most important change is `listen = 0.0.0.0:9000`, which makes php-fpm listen on a TCP port instead of a Unix socket. This is necessary because nginx runs in a separate container and needs to reach php-fpm over the Docker network.

### wordpress.sh
The entrypoint script runs in three stages:
1. Waits for MariaDB to be ready by polling with `mysqladmin ping` on the mariadb host, since WordPress cannot be configured without a working database connection.
2. If WordPress is not yet configured (checked by the absence of `wp-config.php`), it downloads the WordPress core files, creates the configuration file with the database credentials from environment variables, installs WordPress with the admin user, and creates a second regular user — both required by the subject.
3. Replaces itself with `php-fpm8.2` via `exec`, making it PID 1.

## Nginx setup
### Directory structure:
```
nginx/
├── Dockerfile
├── .dockerignore
├── tools/
└── conf/
	└── nginx.conf
```

### Dockerfile
The Dockerfile installs nginx and openssl on a Debian Bookworm base image. During the build, a self-signed SSL certificate is generated directly with `openssl req`, so no external certificate authority is needed. The certificate and key are stored in `/etc/ssl/certs/` and `/etc/ssl/private/` respectively. nginx is started in the foreground with `daemon off;` so it runs as PID 1.

### nginx.conf
Configures nginx as the sole entrypoint to the infrastructure. Key settings:
- Listens exclusively on port 443 with SSL — no HTTP traffic is accepted.
- Enforces TLSv1.2 and TLSv1.3 only, as required by the subject.
- Serves WordPress files from `/var/www/wordpress`, the shared volume with the WordPress container.
- Static files are served directly by nginx. PHP files are forwarded to the WordPress container via FastCGI on `wordpress:9000`.

## Docker setup

### Installing Docker
Docker is not available in the default Debian Bookworm repositories, so it must be
installed from Docker's official repository. The steps are:

```bash
# Install dependencies
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow running Docker without sudo
sudo usermod -aG docker $USER
sudo reboot # Needed for the changes to take effect
```

### Environment variables
Before launching the project, copy `.env.example` to `.env` and fill in the values:

```bash
cp srcs/.env.example srcs/.env
```

The `.env` file must never be committed to the repository — it is listed in `.gitignore`. The `.env.example` file contains all the variable names with placeholder values as a reference.

### Data directories
Also, the host directories that back the named volumes must exist. Docker will not create them automatically:

```bash
mkdir -p ~/data/db ~/data/wordpress
```

These paths correspond to the `device` entries in the `volumes` section of `srcs/docker-compose.yml`. MariaDB data persists in `~/data/db` and WordPress files in `~/data/wordpress`, surviving container restarts and rebuilds.

### Domain name
Add the following entry to `/etc/hosts` so the domain resolves to localhost:

```bash
echo "127.0.0.1 samperez.42.fr" | sudo tee -a /etc/hosts
```

### Building and launching the project
With everything set up, the project can be built and launched from the root directory using the Makefile:

```bash
make        # Builds all images and starts all containers in detached mode
make clean  # Stops and removes containers
make fclean # Stops containers, removes volumes and deletes data directories
make re     # Full rebuild from scratch
```

### Useful commands for managing containers
```bash
make logs           # Follow logs from all containers in real time
make ps             # Show status of all containers
make mariadb-shell  # Open a MariaDB client session inside the mariadb container
make wp-shell       # Open a bash session inside the wordpress container
make nginx-shell    # Open a bash session inside the nginx container
```

### Verifying the setup
Once all containers are running, verify each service individually:

```bash
# Check MariaDB — should show the wordpress database
docker exec -it mariadb mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;"

# Check WordPress — should return the installed version number
docker exec -it wordpress wp core version --allow-root --path=/var/www/wordpress

# Check nginx — should return nginx version
docker exec -it nginx nginx -v
```

Finally, open a browser and navigate to `https://samperez.42.fr`. Accept the self-signed certificate warning and the WordPress site should be visible.

### Where data is stored and how it persists
All persistent data lives outside the containers in named volumes backed by host directories:

| Service   | Container path      | Host path            |
|-----------|---------------------|----------------------|
| MariaDB   | `/var/lib/mysql`    | `~/data/db`          |
| WordPress | `/var/www/wordpress`| `~/data/wordpress`   |

This means that running `make clean` (which only removes containers) does not delete any data.  
Only `make fclean` removes the data directories entirely, giving a clean slate for a full rebuild.