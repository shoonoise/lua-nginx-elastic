import unittest
import requests
import time
from urlparse import urljoin


WWW = "http://localhost"
ELASTIC = "http://localhost:9200"


class ElasticSenderTests(unittest.TestCase):

    def get_logs(self):
        resp = requests.get(urljoin(ELASTIC, "log-*/_search?q=host:*"))
        return resp.json()

    def test_hits_counter(self):
        current = self.get_logs()['hits']['total']
        requests.get(urljoin(WWW, '/'))
        time.sleep(1)
        new = self.get_logs()['hits']['total']
        self.assertEqual(new - current, 1)


if __name__ == "__main__":
    unittest.main()
