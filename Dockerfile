# Nginx Lua module to send access logs into elasticsearch
#
# VERSION 1.0

FROM nikicat/ubuntu:12.04
ENV DEBIAN_FRONTEND noninteractive

# Nginx
RUN add-apt-repository ppa:nginx/stable
RUN apt-get update
RUN apt-get install -y liblua5.1-json liblua5.1-socket2 nginx-extras

# Elastic module
ADD nginx-example.conf /etc/nginx/nginx.conf
ADD stat_sender.lua /usr/share/nginx/
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ADD set_elastic_server.sh /

EXPOSE 80

CMD /set_elastic_server.sh && nginx
