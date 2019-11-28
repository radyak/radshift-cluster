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

build.prepare:
	sudo rm -rf .tmp
	mkdir .tmp
	mkdir -p .tmp/etc/gateway
	mkdir -p .tmp/etc/core
	mkdir -p .tmp/var
	mkdir -p .tmp/home/shared

build.dev: build.prepare
	cp ./dev/*.toml .tmp/etc/gateway
	cp backends-config.json .tmp/etc/core
	cp .env .tmp
	cp docker-compose.yml .tmp


build.rpi: build.prepare
	cp ./rpi/*.toml .tmp/etc/gateway
	cp backends-config.json .tmp/etc/core
	cp ./rpi/.env .tmp
	cp docker-compose.yml .tmp

	cd .tmp && tar -cpf package.tar .



## deploy

deploy.rpi: build.rpi
	scp -P $(PORT) .tmp/package.tar $(SSH_USER)@$(HOST):.
	ssh $(SSH_USER)@$(HOST) -p $(PORT) 'rm -rf /var/rs-root/home && rm -rf /var/rs-root/etc && tar -pxvf package.tar -C /var/rs-root/'