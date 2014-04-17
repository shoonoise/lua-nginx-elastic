lua-ngx-elastic
===============

Sending structured access logs into elasticsearch in realtime.

**Disclaimer:** It's early version, so lua code may block nginx worker, be careful and ensure to you have know how it works.

See at `nginx-example.conf`.

## Tests

At best just run `python tests.py` (you need [requests](https://github.com/kennethreitz/requests) and [docker](https://github.com/dotcloud/docker-py) libs installed)

If you got exceptions (especially http connection error) look at *constants* in `tests.py`, probably you should change them.
