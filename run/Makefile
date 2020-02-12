#!make
include .deploy.env
export


default:
	echo "No default goal defined"


## run (dev)

run.cluster: stop.cluster build.dev
	docker-compose up

run.cluster.minimal: stop.cluster build.dev
	docker-compose up -d gateway core

run.cluster.rebuild: stop.cluster build.dev
	docker-compose up -d --build

stop.cluster:
	docker-compose down


## build
# TODO: parameterize the build dir (e.g. DIR=rpi)

build.prepare:
	git pull
	sudo rm -rf .tmp
	mkdir .tmp
	mkdir -p .tmp/etc/gateway
	mkdir -p .tmp/etc/core
	mkdir -p .tmp/var

build.dev: build.prepare
	cp ./dev/*.toml .tmp/etc/gateway
	cp backends-config.json .tmp/etc/core
	cp .env .tmp
	cp docker-compose.yml .tmp
	cp backup.sh .tmp


build.rpi: build.prepare
	cp ./rpi/*.toml .tmp/etc/gateway
	cp backends-config.json .tmp/etc/core
	cp ./rpi/.env .tmp
	cp docker-compose.yml .tmp
	cp backup.sh .tmp

	cd .tmp && tar -cpf package.tar .



## deploy

delpoy.clean: 
	ssh $(SSH_USER)@$(HOST) -p $(PORT) 'rm -rf /var/rs-root/etc'

deploy.rpi: build.rpi
	scp -P $(PORT) .tmp/package.tar $(SSH_USER)@$(HOST):.
	ssh $(SSH_USER)@$(HOST) -p $(PORT) 'tar -pxvf package.tar -C /var/rs-root/'
	ssh $(SSH_USER)@$(HOST) -p $(PORT) 'mv /var/rs-root/backup.sh . && chmod +x backup.sh'