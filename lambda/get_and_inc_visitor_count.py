import json

import boto3
from botocore.exceptions import ClientError

client = boto3.client('dynamodb')

def lambda_handler(event, context):
    try:
        response = client.update_item(
            TableName='CounterTable',
            Key={
                'CounterType': {
                    'S': 'VisitorCount'
                },
            },
            UpdateExpression='SET VisitCount = if_not_exists(VisitCount, :start) + :inc',
            ExpressionAttributeValues={
                ':inc': {'N': '1'},    # The value to add
                ':start': {'N': '0'}   # The initial value if VisitCount is missing
            },
            ReturnValues='UPDATED_NEW' 
        )

        new_count = response['Attributes']['VisitCount']['N']
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': 'https://zheng-pei.com'
            },
            'body': json.dumps({'visitor_count': int(new_count)})
        }

    except ClientError as e:
        print(f"DynamoDB Client Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'DynamoDB Client Error', 'details': str(e)})
        }
    
    except Exception as e:
        print(f"An unknown error occurred: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Unexpected Server Error', 'details': str(e)})
        }
