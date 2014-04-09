#!/bin/bash

sed -i "s/localhost/$ELASTIC_PORT_9200_TCP_ADDR/" /etc/nginx/nginx.conf
