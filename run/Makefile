#!make
include .deploy.env
export


default:
	echo "No default goal defined"


## run (dev)

run.cluster: build.dev stop.cluster
	docker-compose up

run.cluster.minimal: build.dev stop.cluster
	docker-compose up -d gateway core mongodb

run.cluster.rebuild: build.dev stop.cluster
	docker-compose up -d --build

stop.cluster:
	docker-compose down


## build
# TODO: parameterize the build dir (e.g. DIR=rpi)

build.dev:
	sudo rm -rf .tmp
	mkdir .tmp
	mkdir -p .tmp/etc/traefik
	mkdir -p .tmp/etc/core
	mkdir -p .tmp/var
	mkdir -p .tmp/home/shared

	cp ./dev/*.toml .tmp/etc/traefik
	cp ./dev/.env.* .tmp/etc/core


build.rpi:
	sudo rm -rf .tmp
	mkdir .tmp
	mkdir -p .tmp/etc/traefik
	mkdir -p .tmp/etc/core
	mkdir -p .tmp/var
	mkdir -p .tmp/home/shared

	cp ./rpi/*.toml .tmp/etc/traefik
	cp ./rpi/.env.* .tmp/etc/core

	cp .env .tmp
	cp docker-compose.yml .tmp

	cd .tmp && tar -pcf package.tar .

	scp -P 2294 .tmp/package.tar pirate@radshift:.
	ssh pirate@radshift -p 2294 'rm -rf /var/rs-root/* && tar -xvf package.tar -C /var/rs-root/'
	


## deploy

deploy.config:
	scp -P $(PORT) rpi.config/.env.conf $(SSH_USER)@$(HOST):/home/pirate/conf/.env.conf
	scp -P $(PORT) rpi.config/.env.key $(SSH_USER)@$(HOST):/home/pirate/conf/.env.key

deploy.env:
	scp -P $(PORT) .env $(SSH_USER)@$(HOST):.env

deploy.cluster-config:
	scp -P $(PORT) docker-compose.yml $(SSH_USER)@$(HOST):docker-compose.yml

deploy.radhub-config:
	scp -P $(PORT) ../radhub/radhub-backends.json $(SSH_USER)@$(HOST):radhub-backends.json

deploy: deploy.rpi.config deploy.rpi.env deploy.rpi.cluster-config deploy.rpi.radhub-config
