#!/bin/bash

sed -i "s/%ELASTICSEARCH_HOST%/$ELASTIC_PORT_9200_TCP_ADDR/" /etc/nginx/nginx.conf
