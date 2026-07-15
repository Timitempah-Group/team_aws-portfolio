import json
import boto3
import uuid
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('portfolio-items')


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError


def handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', '')

    if method == 'POST':
        body = json.loads(event.get('body', '{}'))
        item_id = str(uuid.uuid4())
        item = {
            'id': item_id,
            'name': body.get('name', 'unnamed'),
            'description': body.get('description', '')
        }
        table.put_item(Item=item)
        return {
            'statusCode': 201,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(item, default=decimal_default)
        }

    elif method == 'GET':
        response = table.scan()
        items = response.get('Items', [])
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(items, default=decimal_default)
        }

    return {
        'statusCode': 405,
        'body': json.dumps({'error': 'Method not allowed', 'received_method': method})
    }
