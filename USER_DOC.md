_This project has been created as part of the 42 curriculum by samperez_

# Inception - USER_DOC
The purpose of this document, is to illustrate how an end user can:
- Understand what services are provided by the stack.
- Start and stop the project.
- Access the website and the administration panel.
- Locate and manage credentials.
- Check that the services are running correctly.

## What services are provided
This project runs three services, each inside its own isolated container:

- **MariaDB** — the database where all WordPress content is stored (posts, users, settings, etc.). You will never interact with it directly.
- **WordPress** — the content management system that powers the website. It handles all the logic and content.
- **nginx** — the web server that receives your browser requests and serves the website. It is the only service directly accessible from outside.

## Starting and stopping the project
All commands must be run from the root folder of the project (`Inception_SF/`).

To start the project:
```bash
make
```
This will build the necessary images if they don't exist yet, and start all three services. The first time may take a few minutes.

To stop the project without losing any data:
```bash
make clean
```

To stop the project and delete all data (full reset):
```bash
make fclean
```

## Accessing the website
Once the project is running, open a browser and go to:  
https://samperez.42.fr
Your browser will show a security warning about the certificate — this is expected, as the project uses a self-signed certificate for development purposes. Click "Advanced" and then "Accept the risk and continue" (or equivalent depending on your browser) to proceed.

You should see the WordPress website homepage.

## Accessing the administration panel
To manage the website content, go to:  
https://samperez.42.fr/wp-admin

Log in with the administrator credentials found in the `.env` file (`WP_ADMIN_USER` and `WP_ADMIN_PASSWORD`). From here you can create posts, manage users, install plugins, and configure the site.

## Locating and managing credentials
All credentials are stored in `srcs/.env`. This file is never uploaded to the repository for security reasons. It contains:

| Variable            | Description                        |
|---------------------|------------------------------------|
| `MYSQL_USER`        | MariaDB user for WordPress         |
| `MYSQL_PASSWORD`    | Password for that user             |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password            |
| `WP_ADMIN_USER`     | WordPress administrator username   |
| `WP_ADMIN_PASSWORD` | WordPress administrator password   |
| `WP_USER`           | Second WordPress user              |
| `WP_USER_PASSWORD`  | Password for the second user       |

If you need to change any credential, edit the `.env` file and run `make re` to rebuild the project from scratch.

## Checking that the services are running correctly
To see if all three containers are up and running:
```bash
make ps
```

You should see three containers (`mariadb`, `wordpress`, `nginx`) with status `Up`.

To see the live logs of all services:
```bash
make logs
```

If something looks wrong, this is the first place to look for error messages.

When you are done, to erase the containers:
```bash
make clean
```

This will not erase the data, if that was your goal, just run
```bash
make fclean
```
