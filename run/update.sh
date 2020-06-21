#!/bin/bash

container=$1

docker-compose pull $container
docker-compose stop $container
docker-compose rm -f $container
docker-compose up -d --force-recreate $container
