import redis
import logging
import json
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    shard = event.get('pathParameters').get('shard')
    host = os.environ.get('redis_host')
    r = redis.Redis(host)

    data = r.hgetall(shard)
    body = {}

    for k,v in data.items():
        body[k.decode()] = v.decode()

    response = {
        'statusCode': 200,
        'headers': {
            'Content-type': 'application/json'
        },
        'body': json.dumps({shard: body})
    }

    return response
