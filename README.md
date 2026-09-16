_This project has been created as part of the 42 curriculum by samperez_

# Inception

## Description
Inception is a system administration project from the 42 curriculum. The goal is to set up a small but complete web infrastructure using Docker, where each service runs in its own container. The result is a working WordPress website served over HTTPS, backed by a MariaDB database, and fronted by an nginx web server.

The entire infrastructure is orchestrated with Docker Compose and built from scratch using custom Dockerfiles — no pre-built images from DockerHub are used.

### Use of Docker
Instead of installing services directly on the host machine, each service runs in an isolated container built from a Debian Bookworm base image. This keeps the host clean and makes the infrastructure reproducible on any machine.

The three services and their roles are:
- **nginx** — the only entry point to the infrastructure, serving HTTPS on port 443
- **WordPress + php-fpm** — the content management system, processing PHP requests
- **MariaDB** — the database storing all WordPress content

### Design choices

#### Virtual Machines vs Docker
A Virtual Machine emulates an entire computer including its own OS kernel, which makes it heavy and slow to start. Docker containers share the host's kernel and only isolate the application layer, making them much lighter and faster. For this project, Docker is the right tool because we want isolated services without the overhead of running multiple full operating systems.

#### Secrets vs Environment Variables
Environment variables (stored in `.env`) are convenient for development but are visible to any process running in the container. Docker secrets are more secure — they are mounted as files inside the container and never exposed as environment variables. This project uses `.env` for simplicity, but the subject recommends Docker secrets for any sensitive credentials in a production environment.

#### Docker Network vs Host Network
With host networking, a container shares the host's network directly — any port the container opens is immediately accessible from outside. With a Docker network (bridge mode), containers communicate through an isolated virtual network and only expose ports explicitly. This project uses a bridge network (`inception_net`) so that MariaDB and WordPress are only reachable from within the network, with nginx as the sole gateway from outside.

#### Docker Volumes vs Bind Mounts
A bind mount links a specific path on the host directly into the container. A named volume is managed by Docker and abstracts the storage location. This project uses named volumes with a `driver_opts` bind to a specific host path (`~/data/`), combining the portability of named volumes with the explicit data location required by the subject.

## Instructions

### Prerequisites
- A Debian Bookworm virtual machine
- Docker and Docker Compose installed (see `DEV_DOC.md` for installation steps)
- The domain `samperez.42.fr` added to `/etc/hosts`:
```bash
echo "127.0.0.1 samperez.42.fr" | sudo tee -a /etc/hosts
```

### Setup
Clone the repository and create the `.env` file from the example:
```bash
cp srcs/.env.example srcs/.env
# Edit srcs/.env and fill in your credentials
```

### Running the project
From the root of the repository:
```bash
make        # Build and start all containers
make clean  # Stop and remove containers
make fclean # Full reset including all data
make re     # Clean rebuild from scratch
```

Once running, open a browser and go to `https://samperez.42.fr`.

For more detailed instructions, refer to:
- `DEV_DOC.md` — for developers setting up or modifying the project
- `USER_DOC.md` — for end users interacting with the running project

## Resources

### Documentation
- [Docker official documentation](https://docs.docker.com)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [nginx documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [WP-CLI documentation](https://wp-cli.org/)
- [php-fpm documentation](https://www.php.net/manual/en/install.fpm.php)

### Guides and articles
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Understanding PID 1 in Docker containers](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)
- [Docker named volumes vs bind mounts](https://docs.docker.com/storage/volumes/)
- [TLS configuration in nginx](https://nginx.org/en/docs/http/configuring_https_servers.html)

### AI usage
Claude (Anthropic) was used as a learning companion throughout this project, in the following ways:

- **MariaDB** — helped design the entrypoint script flow (temporary local startup, SQL initialization, clean shutdown before final launch) and explained the reasoning behind each step.
- **WordPress** — helped structure the `wordpress.sh` script and explained the role of WP-CLI and php-fpm configuration.
- **nginx** — helped write the `nginx.conf` and explained FastCGI, the role of `try_files`, and TLS configuration.
- **Docker Compose** — helped set up named volumes with host path binding and explained the difference between `depends_on` and actual service readiness.
- **Documentation** — helped write and structure `DEV_DOC.md` and `USER_DOC.md` following a consistent style.

In all cases, generated content was reviewed, understood, and adapted before being included in the project.