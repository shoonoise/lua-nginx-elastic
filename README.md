lua-ngx-elastic
===============

Sending structured access logs into elasticsearch in realtime.

**Disclaimer:** It's early version, so lua code may block nginx worker, be careful and ensure to you have know how it works.

See at `nginx-example.conf`.

## Tests

 - Build docker container from this repo:
 `docker build -t ngx_elastic_img .`

 - Run elastic search server, for example, from this container:
`docker run -d -p 9200:9200 --name=elasticlog orchardup/elasticsearch`

 - Run `ngx_elastic_img` container:
 `docker run -p 80:80 -d --link=elasticlog:ELASTIC --name ngx_elastic ngx_elastic_img`

- Run `python tests.py` (you need requests lib installed)
