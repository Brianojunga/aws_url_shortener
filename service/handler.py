import json 
import boto3
import string 
import random

dynamodb = boto3.resource('dynamodb') 
table = dynamodb.Table('URLShortener')

def generate_short_code():
    chars = string.ascii_letters + string.digits
    return "".join(random.choice(chars) for _ in range(6))

def lambda_handler(event, context):
    http_method = event['httpMethod']

    if http_method == 'POST':
        body = json.loads(event['body'])
        original_url = body.get("original_url")
        short_code = generate_short_code()

        table.put_item( 
            Item = {
                'short_code': short_code, 
                'long_url': f"https://{original_url}"
            }
        )

        return {
            'statusCode': 200, 
            'body': json.dumps({'short_code': short_code})
        }
    elif http_method == 'GET':
        path_params = event.get('pathParameters') or {}
        short_code = path_params.get('shortCode')
        
        if not short_code:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Missing short code'})
            }
        
        response = table.get_item(
            Key = {
                'short_code': short_code
            }
        )

        if "Item" in response:
            long_url = response['Item']['long_url']
            return {
                'statusCode': 301,
                'headers': {
                    "location": long_url,
                    "Content-Type": "application/json"
                },
                'body' : json.dumps({'message' : f"Redirecting to {long_url}"})
            }
    else:
        return {
            'statusCode': 400,
            'body' : json.dumps({'error': 'Short code not found'})
        } 