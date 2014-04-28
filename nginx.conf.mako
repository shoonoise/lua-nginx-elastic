worker_processes 1;
daemon off;

error_log stderr notice;

events {
    worker_connections 1024;
}

http {

    upstream elasticsearch {
        # elastic search server
        <%! import os %>
        server ${os.environ['ELASTICSEARCH_PORT_9200_TCP_ADDR']}:${os.environ['ELASTICSEARCH_PORT_9200_TCP_PORT']} max_fails=3 fail_timeout=30s;
    }

    upstream backend {
        server 127.0.0.1:8080 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 8080;

        location /ok/ {
            return 200;
        }

    }

    server {
        listen 80 default_server;
 
        location / {
            # It is necessary option
            keepalive_timeout 0;
            lua_need_request_body on;
            proxy_ignore_client_abort on;
            # set it 'on' if you want to log POST body
            set $send_body off;
            set $target_url /target;
            content_by_lua_file /usr/share/nginx/stat_sender.lua;
        }

        location /target {
            internal;
            rewrite ^/target/(.*)$ /\$1 break;
            # pass request to location/upstream/fastcgi/etc
            proxy_pass http://backend/;
        }

        location ~ /elasticsearch {
            internal;
            rewrite ^/elasticsearch/(.*)$ /$1 break;
            proxy_connect_timeout 5s;
            proxy_send_timeout 5s;
            proxy_read_timeout 5s;
            proxy_pass http://elasticsearch;
        }

    }
}
