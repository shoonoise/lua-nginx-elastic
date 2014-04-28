import os
import unittest
import requests
import time
from urlparse import urljoin


class ElasticSenderTests(unittest.TestCase):

    def get_logs(self):
        resp = requests.get('http://{}:{}/log-*/_search?q=host:*'.format(os.environ['ELASTICSEARCH_PORT_9200_TCP_ADDR'], os.environ['ELASTICSEARCH_PORT_9200_TCP_PORT']))
        return resp.json()

    def test_hits_counter(self):
        current = self.get_logs()['hits']['total']
        requests.get('http://{}:{}/ok/'.format(os.environ['NGINX_PORT_80_TCP_ADDR'], os.environ['NGINX_PORT_80_TCP_PORT']))
        # Time of sleep dependent on your env, you may change it as you need
        time.sleep(3)
        new = self.get_logs()['hits']['total']
        self.assertEqual(new, current + 1)


if __name__ == "__main__":
    unittest.main()
