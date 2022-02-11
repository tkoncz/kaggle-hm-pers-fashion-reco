ifndef APP_NAME
	APP_NAME=$(shell basename `pwd`)
endif

ifneq ($(findstring .env,$(wildcard .env)), )
    include .env
endif

export

DOCKER_UP:=docker-compose up -d
DOCKER_DOWN:=docker-compose down
DOCKER_BUILD:=docker build --build-arg APP_NAME=$(APP_NAME)

up:
	@$(DOCKER_UP)
down:
	@$(DOCKER_DOWN)
start:
	@$(DOCKER_UP)

build: image-base

image-%: suffix=$(subst image-,,$@)
image-%:
	@echo Building: $(APP_NAME)-$(suffix)
	@$(DOCKER_BUILD) \
		--no-cache\
		-f docker-build/Dockerfile.$(suffix) \
		-t $(APP_NAME):$(suffix) \
		.

local_shell:
	@docker-compose run --service-ports --rm shell /bin/bash

.PHONY: start up down stop
.PHONY: local_shell
.PHONY: build image-%
