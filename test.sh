#!/bin/bash -e

BASEDIR=$(dirname $0)

trap "docker ps -q -a | xargs docker rm -f" EXIT SIGTERM SIGQUIT SIGINT

docker run --name elasticsearch -d orchardup/elasticsearch:latest
docker build -t nginx-with-lua-stats $BASEDIR
docker run --name nginx --link elasticsearch:elasticsearch -d nginx-with-lua-stats
docker run -v `realpath ${BASEDIR}`:/root/src:ro -t -i --link elasticsearch:elasticsearch --link nginx:nginx nikicat/python-testing tox || true
docker logs nginx
docker logs elasticsearch
