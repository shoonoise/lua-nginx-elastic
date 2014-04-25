# Nginx Lua module to send access logs into elasticsearch
#
# MAINTAINER Alexander Kushnarev <avkushnarev@gmail.com>
#
# VERSION 1.0

FROM yandex/ubuntu:latest

# Nginx
RUN add-apt-repository ppa:nginx/stable
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y liblua5.1-json liblua5.1-socket2 nginx-extras

# Elastic module
ADD nginx-example.conf /etc/nginx/nginx.conf
ADD stat_sender.lua /usr/share/nginx/
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ADD set_elastic_server.sh /

EXPOSE 80

CMD /set_elastic_server.sh && nginx
