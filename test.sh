#!/bin/bash -e

basedir=`dirname $0`
basepath=`realpath $basedir`
cids=""

function clean_containers() {
    docker rm -f $cids
}

trap clean_containers EXIT SIGTERM SIGQUIT SIGINT

cid=`docker run --name elasticsearch -d orchardup/elasticsearch:latest`
cids="$cids $cid"
docker build -t nginx-with-lua-stats $basedir
cid=`docker run --name nginx --link elasticsearch:elasticsearch -d nginx-with-lua-stats`
cids="$cids $cid"
docker run --rm -v $basepath:/root/src:ro -t -i --link elasticsearch:elasticsearch --link nginx:nginx nikicat/python-testing tox
docker logs nginx
docker logs elasticsearch
