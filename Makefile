#!/bin/sh
SHELL = /bin/sh # Use sh syntax

# ARGUMENT - ENV
ifndef ENV
ENV = dev
else
ENV = $(ENV)
endif

ifeq ($(ENV),dev)
BIN_PHP = php
ENVIRONMENT = develop
else ifeq ($(ENV),staging)
BIN_PHP = php
ENVIRONMENT = staging
else ifeq ($(ENV),preprod)
BIN_PHP = php
ENVIRONMENT = preproduction
else ifeq ($(ENV),prod)
BIN_PHP = php
ENVIRONMENT = production
else
$(error ENV argument is required : dev|staging|preprod|prod)
endif

# VARIABLES
SYMFONY_CONSOLE = $(BIN_PHP) bin/console
APP_NAME = entreprise_b
DOMAIN = $(APP_NAME).fr
ENVIRONMENT_TEST = test

ifeq ($(OS), Windows_NT)
	CURRENT_UID = $(cmd id -u)
	CURRENT_GID = $(cmd id -g)
else
	CURRENT_UID = $(shell id -u)
	CURRENT_GID = $(shell id -g)
endif

# EXEC
EXEC_CONTAINER = docker exec -it -u $(CURRENT_UID):$(CURRENT_GID)

# RUN
## www_app from docker-compose.yml
RUN_APP = docker-compose run --rm -u $(CURRENT_UID):$(CURRENT_GID) www_app
RUN_NODE = docker-compose run --rm -u $(CURRENT_UID):$(CURRENT_GID) node_app

# HELP
.DEFAULT_GOAL = help

# Display the list commands whit the command "make"
ifeq ($(OS), Windows_NT)
help:
	@echo "/!\ Make help is disabled on windows /!\ ";
.PHONY: help
else
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help
endif

##-----------------------------------------
## PROJECT
##-----------------------------------------

init: ## Init project
init: generate-root-env-files generate-app-env-files  docker-compose

install: ## Install project
install: init docker-build

install-full: ## Install then start project
install-full: install docker-run composer-install app-fix-folders-files update

install-full-fixture: ## Install then start project with fixture
install-full-fixture: install docker-run composer-install app-fix-folders-files create front-dev-build

restore-fixture: ## Retore fixture
	- make app-db-with-fixture

app-db-with-fixture: ## Load db with fixture
	- $(EXEC_CONTAINER) $(APP_NAME)_www /bin/sh -c "make db-with-fixture"

##-----------------------------------------
## APPLICATION
##-----------------------------------------

app-fix-folders-files: ## Fix folders and files for application
	cd app && make fix-folders-files

create: ## Create application (db, front)
	- $(RUN_APP) bin/$(ENVIRONMENT)/create.sh
	- $(RUN_APP) bin/$(ENVIRONMENT_TEST)/create.sh

update: ## Update application (db, front)
	- make docker-run
	- $(RUN_APP) bin/$(ENVIRONMENT)/update.sh
	- $(RUN_APP) bin/$(ENVIRONMENT_TEST)/update.sh
	- make front-dev-build

##-----------------------------------------
## QUALITY AND TESTS
##-----------------------------------------

QA-test: ## Active quality and phpunit
QA-test: quality phpunit

##-----------------------------------------
## QUALITY
##-----------------------------------------

quality: ## Global quality (app)
quality: phpfixer phpstan lint

lint: ## Run Lint globaly (app)
lint:
	$(RUN_APP) make lint

phpfixer: ## Run PhpCsFixer globaly (app)
# phpfixer: app/.php-cs-fixer-dist.php
	$(RUN_APP) make phpfixer

phpfixer-to-gitlab: ## Run PhpCsFixer globaly into gitlab (app)
	$(RUN_APP) make phpfixer-to-gitlab

phpstan: ## Run PhpStan globaly (app)
phpstan: app/phpstan.dist.neon
	$(RUN_APP) make phpstan

# prettier: ## Run Prettier globaly (app)
# prettier: app/.prettierrc
# 	$(RUN_NODE) make prettier

##-----------------------------------------
## TESTS
##-----------------------------------------

behat: ## Run all behat tests (app)
	$(RUN_APP) make behat

phpunit: ## Run all units tests (app)
phpunit: phpunit-test phpunit-test-coverage

phpunit-test: ## Run unit tests (app)
	$(RUN_APP) make phpunit-test

phpunit-test-coverage: ## Run unit tests with coverage (app)
	$(RUN_APP) make phpunit-test-coverage

phpunit-to-gitlab: ## Run all units tests (app)
	make phpunit-test-coverage-to-gitlab

phpunit-test-to-gitlab: ## Run unit tests (app)
	$(RUN_APP) make phpunit-test-to-gitlab

phpunit-test-coverage-to-gitlab: ## Run unit tests with coverage (app)
	$(RUN_APP) make phpunit-test-coverage-to-gitlab

##-----------------------------------------
## DOCKER
##-----------------------------------------

start: ## start application containers
	make docker-start

stop: ## Stop application containers
	make docker-stop

build: ## Build and rebuild application containers
	make docker-build

run: ## run Docker in the background
	make docker-run
	@echo "Accès au projet en local sur : http://127.0.0.1:8971/"
	@echo "Accès au PHPMyAdmin du projet en local sur : http://127.0.0.1:8080/"
	@echo "Accès au MailDev du projet en local sur : http://127.0.0.1:8081/"

down: ## stop and delete all containers, networks, and volumes associated with a Docker Compose project. Limited to the specific project
	make docker-down

docker-build: ## Build and rebuild application containers
	docker-compose build

docker-start: ## start application containers
	docker-compose start

docker-stop: ## Stop application containers
	docker-compose stop

docker-exec-php: ## Enter into the sh of PHP
	docker exec -it entreprise_b_www sh

docker-exec-node: ## Enter into the sh of Node
	docker exec -it entreprise_b_node sh

docker-run: ## run Docker in the background
	docker-compose up -d

docker-down: ## stop and delete all containers, networks, and volumes associated with a Docker Compose project. Limited to the specific project
	docker-compose down

docker-compose: ## Generate docker-composer.yml file
docker-compose: docker-compose.yml.dist
	@if [ -f docker-compose.yml ]; then \
	    echo 'docker-compose.yml already exists'; \
	else \
	    echo cp docker-compose.yml.dist docker-compose.yml; \
	    cp docker-compose.yml.dist docker-compose.yml; \
	fi

##-----------------------------------------
## RUN & EXEC cli
##-----------------------------------------

container-php: ## Go into app container to run command (ex: composer require, bin/console, etc)
	$(EXEC_CONTAINER) $(APP_NAME)_www /bin/sh

container-php-2: ## Create temporary container of app
	$(RUN_APP) /bin/sh

container-node: ## Create temporary container of node
	$(RUN_NODE) /bin/sh

##-----------------------------------------
## FRONT
##-----------------------------------------

front-dev-build: ## Build front for dev
	- make docker-run
	$(RUN_NODE) sh -c "make front-dev-build"

front-dev-watch: ## Watch front for dev
	$(RUN_NODE) sh -c "make front-dev-watch"

front-production-build: ## Build front for production
	$(RUN_NODE) sh -c "make front-production-build"

##-----------------------------------------
## DATABASE
##-----------------------------------------

db-load-latest: ## Load latest SQL file - depending env
	$(SYMFONY_CONSOLE) doctrine:database:drop --force
	$(SYMFONY_CONSOLE) doctrine:database:create
	$(SYMFONY_CONSOLE) doctrine:database:import latest.$(ENV).sql

##-----------------------------------------
## COMPOSER
##-----------------------------------------

composer-install: ## Composer install
	$(RUN_APP) sh -c "make composer-install"

composer-update: ## Composer update
	$(RUN_APP) sh -c "make composer-update"

##-----------------------------------------
## ENV
##-----------------------------------------

generate-env-files: ## Generate env files
generate-env-files: generate-env

ifeq ($(OS), Windows_NT)
generate-env: ## Generate .env (windows)
generate-env: app/.env.dist
	@if exist .env; then \
		echo '.env already exists';\
	else \
		echo cp .env.dist .env;\
		cp .env.dist .env;\
  	fi
else
generate-env: ## Generate .env (unix)
generate-env: app/.env.dist
	@if [ -f .env ]; then \
		echo '.env already exists';\
	else \
		echo cp .env.dist .env;\
		cp .env.dist .env;\
  	fi
endif

generate-app-env-files: ## Generate env files (application)
generate-app-env-files:
	cd app && make generate-env-files

# ----------------------------------------

generate-root-env-files-root: ## Generate env files
generate-root-env-files-root: generate-root-env

ifeq ($(OS), Windows_NT)
generate-root-env: ## Generate root .env (windows)
generate-root-env: .env.dist
	@if exist .env; then \
		echo '.env already exists';\
	else \
		echo cp .env.dist .env;\
		cp .env.dist .env;\
  	fi
else
generate-root-env: ## Generate root .env (unix)
generate-root-env: .env.dist
	@if [ -f .env ]; then \
		echo '.env already exists';\
	else \
		echo cp .env.dist .env;\
		cp .env.dist .env;\
  	fi
endif

generate-root-env-files: ## Generate root env files (root)
generate-root-env-files:
	make generate-root-env-files-root

##-----------------------------------------
## END
##-----------------------------------------