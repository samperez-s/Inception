# Paths
COMPOSE		= docker compose -f srcs/docker-compose.yml
DATA_DIR	= $(HOME)/data

all:
	mkdir -p $(DATA_DIR)/db $(DATA_DIR)/wordpress
	$(COMPOSE) up --build -d

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down --volumes
	sudo rm -rf $(DATA_DIR)/db $(DATA_DIR)/wordpress

re: fclean all

# Testing rules
logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

mariadb-shell:
	docker exec -it mariadb mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

wp-shell:
	docker exec -it wordpress bash

nginx-shell:
	docker exec -it nginx bash

.PHONY: all clean fclean re logs ps mariadb-shell wp-shell nginx-shell