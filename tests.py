import os
import unittest
import requests
import time
import docker
from urlparse import urljoin


WWW = "http://localhost:8111"
ELASTIC = "http://localhost:9200"
DOCKER_API = "http://localhost:4243"


class ElasticSenderTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.docker_client = docker.Client(base_url=DOCKER_API,
                                          version='1.9',
                                          timeout=30)

        cls.elastic_container_id = cls.docker_client.create_container("orchardup/elasticsearch").get('Id')
        cls.docker_client.build(path=os.path.abspath(os.path.curdir), tag="ngx_elastic_img", rm=True)
        cls.nginx_container_id = cls.docker_client.create_container("ngx_elastic_img").get('Id')
        cls.docker_client.start(cls.elastic_container_id, port_bindings={9200: 9200})
        cls.elastic_container_name = cls.docker_client.inspect_container(cls.elastic_container_id)["Name"]
        cls.docker_client.start(cls.nginx_container_id, port_bindings={80: 80}, links={cls.elastic_container_name: "ELASTIC"})
        time.sleep(10)

    @classmethod
    def tearDownClass(cls):
        cls.docker_client.stop(cls.elastic_container_id)
        cls.docker_client.stop(cls.nginx_container_id)
        cls.docker_client.remove_container(cls.elastic_container_id)
        cls.docker_client.remove_container(cls.nginx_container_id)

    def get_logs(self):
        resp = requests.get(urljoin(ELASTIC, "log-*/_search?q=host:*"))
        return resp.json()

    def test_hits_counter(self):
        current = self.get_logs()['hits']['total']
        requests.get(urljoin(WWW, '/'))
        time.sleep(3)
        new = self.get_logs()['hits']['total']
        self.assertEqual(new - current, 1, "Current: %s" % current)


if __name__ == "__main__":
    unittest.main()
