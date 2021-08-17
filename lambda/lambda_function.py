import redis
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    #logger.info("Request: %s", event)
    shard = event.get('pathParameters').get('shard')

    r = redis.Redis(host='')

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
