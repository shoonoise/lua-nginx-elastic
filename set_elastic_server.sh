#!/bin/bash

sed -i "s/localhost/$elasticsearch_elasticlog_HOST/" /etc/nginx/nginx.conf
