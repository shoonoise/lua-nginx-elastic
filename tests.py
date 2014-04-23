import os
import unittest
import requests
import time
import docker
import logging
from urlparse import urljoin


WWW = "http://localhost:8080"
ELASTIC = "http://localhost:9200"
DOCKER_API = "http://localhost:4243"
DEBUG = False


class ElasticSenderTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.logger = logging.getLogger("docker api")
        cls.logger.setLevel(logging.DEBUG)
        if DEBUG:
            cls.logger.addHandler(logging.StreamHandler())
        else:
            cls.logger.addHandler(logging.FileHandler("tests.log"))

        cls.dc = docker.Client(base_url=DOCKER_API, version='1.9',
                               timeout=30)

        map(cls.logger.debug,
            cls.dc.pull("orchardup/elasticsearch", stream=True))
        cls.elastic_id = cls.dc.create_container(
            "orchardup/elasticsearch").get('Id')
        cls.dc.start(cls.elastic_id, port_bindings={9200: 9200})
        cls.elastic_name = cls.dc.inspect_container(cls.elastic_id)["Name"]

        map(cls.logger.debug,
            cls.dc.build(path=os.path.abspath(os.path.curdir),
                         tag="ngx_elastic_img",  rm=True, stream=True))
        cls.nginx_id = cls.dc.create_container("ngx_elastic_img").get('Id')

        cls.dc.start(cls.nginx_id, port_bindings={80: 8080},
                     links={cls.elastic_name: "ELASTIC"})
        # Time of sleep dependent on your env, you may change it as you need
        time.sleep(10)

    @classmethod
    def tearDownClass(cls):
        map(cls.logger.debug, cls.dc.logs(cls.elastic_id,
                                          stdout=True, stderr=True,
                                          stream=False))

        map(cls.logger.debug, cls.dc.logs(cls.nginx_id,
                                          stdout=True, stderr=True,
                                          stream=False))

        cls.dc.stop(cls.elastic_id)
        cls.dc.stop(cls.nginx_id)
        cls.dc.remove_container(cls.elastic_id)
        cls.dc.remove_container(cls.nginx_id)
        cls.dc.remove_image("ngx_elastic_img")
        cls.dc.remove_image("orchardup/elasticsearch")

    def get_logs(self):
        resp = requests.get(urljoin(ELASTIC, "log-*/_search?q=host:*"))
        return resp.json()

    def test_hits_counter(self):
        current = self.get_logs()['hits']['total']
        requests.get(urljoin(WWW, '/ok/'))
        # Time of sleep dependent on your env, you may change it as you need
        time.sleep(3)
        new = self.get_logs()['hits']['total']
        self.assertEqual(new - current, 1, "Current: %s" % current)


if __name__ == "__main__":
    unittest.main()
