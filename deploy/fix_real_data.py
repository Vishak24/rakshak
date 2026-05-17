"""
Deploy real-data-only Lambdas, add /police/sos/{id}/status route, delete test SOS records.

Prerequisites:
  export RAKSHAK_AWS_ACCESS_KEY_ID=...
  export RAKSHAK_AWS_SECRET_ACCESS_KEY=...
  python3 deploy/fix_real_data.py
"""
import boto3, io, zipfile, json, os, time
from botocore.exceptions import ClientError

REGION     = 'ap-south-1'
ACCOUNT_ID = '468704514492'
API_ID     = 'aksdwfbnn5'
ROLE_ARN   = f'arn:aws:iam::{ACCOUNT_ID}:role/rakshak-lambda-role'

KEY_ID = os.environ['RAKSHAK_AWS_ACCESS_KEY_ID']
SECRET = os.environ['RAKSHAK_AWS_SECRET_ACCESS_KEY']

LAMBDA_ENV = {
    'Variables': {
        'AWS_REGION_OVERRIDE': REGION,
        'RAKSHAK_AWS_ACCESS_KEY_ID': KEY_ID,
        'RAKSHAK_AWS_SECRET_ACCESS_KEY': SECRET,
    }
}

lambda_client = boto3.client('lambda', region_name=REGION)
apigw         = boto3.Session(profile_name='default').client('apigatewayv2', region_name=REGION)
ddb           = boto3.resource('dynamodb', region_name=REGION,
                               aws_access_key_id=KEY_ID, aws_secret_access_key=SECRET)

# ── Updated SOS handler ───────────────────────────────────────
SOS_CODE = r'''
import json, os, uuid, boto3
from boto3.dynamodb.conditions import Attr
from datetime import datetime, timedelta

REGION = 'ap-south-1'
KEY_ID = os.environ.get('RAKSHAK_AWS_ACCESS_KEY_ID')
SECRET  = os.environ.get('RAKSHAK_AWS_SECRET_ACCESS_KEY')

def _ddb():
    return boto3.resource('dynamodb', region_name=REGION,
                          aws_access_key_id=KEY_ID, aws_secret_access_key=SECRET)

def _table():
    return _ddb().Table('rakshak-sos-alerts')

CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
}

PATROL_STATUS_MAP = {
    'dispatched': 'Responding',
    'at_scene':   'AtScene',
    'resolved':   'Patrolling',
}

def _update_patrol(patrol_id, new_status):
    patrol_table = _ddb().Table('rakshak-patrols')
    patrol_table.update_item(
        Key={'patrol_id': patrol_id},
        UpdateExpression='SET #s = :s, updated_at = :t',
        ExpressionAttributeNames={'#s': 'status'},
        ExpressionAttributeValues={':s': new_status, ':t': datetime.utcnow().isoformat() + 'Z'},
    )

def lambda_handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path   = event.get('rawPath', '')

    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS, 'body': ''}

    try:
        table = _table()

        # POST /sos/live — citizen creates a new SOS alert
        if method == 'POST' and path.endswith('/sos/live'):
            body = json.loads(event.get('body', '{}') or '{}')
            sos_id  = str(uuid.uuid4())
            now_iso = datetime.utcnow().isoformat() + 'Z'
            item = {
                'sos_id':     sos_id,
                'created_at': now_iso,
                'status':     'active',
                'risk_level': body.get('risk_level', 'HIGH'),
                'latitude':   str(body.get('latitude',  '13.0827')),
                'longitude':  str(body.get('longitude', '80.2707')),
            }
            pincode = body.get('pincode')
            if pincode:
                item['pincode']   = str(pincode)
                item['zone_name'] = str(pincode)
            table.put_item(Item=item)
            return {'statusCode': 201, 'headers': CORS, 'body': json.dumps(item)}

        # GET /sos/live — active/dispatched alerts from the last 24 hours only
        if method == 'GET' and path.endswith('/sos/live'):
            cutoff = (datetime.utcnow() - timedelta(hours=24)).isoformat() + 'Z'
            resp = table.scan(
                FilterExpression=Attr('status').is_in(['active', 'dispatched']) &
                                 Attr('created_at').gte(cutoff)
            )
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps(resp.get('Items', []), default=str)}

        # PATCH /police/sos/{id}/status — officer action; cascades to patrol status
        if method == 'PATCH' and '/police/sos/' in path and path.endswith('/status'):
            sos_id = path.split('/police/sos/')[-1].rsplit('/status', 1)[0]
            body = json.loads(event.get('body', '{}') or '{}')
            new_sos_status = body.get('status', '')
            patrol_id = body.get('patrol_id')

            now_iso = datetime.utcnow().isoformat() + 'Z'
            update_expr = 'SET #s = :s, updated_at = :t'
            expr_values = {':s': new_sos_status, ':t': now_iso}

            if patrol_id:
                update_expr += ', patrol_id = :pid'
                expr_values[':pid'] = patrol_id

            table.update_item(
                Key={'sos_id': sos_id},
                UpdateExpression=update_expr,
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues=expr_values,
            )

            # Resolve patrol_id: body → existing SOS record → auto-assign nearest
            if not patrol_id:
                sos_item = table.get_item(Key={'sos_id': sos_id}).get('Item', {})
                patrol_id = sos_item.get('patrol_id')

                # Auto-assign nearest available patrol on first dispatch
                if not patrol_id and new_sos_status == 'dispatched':
                    sos_zone = sos_item.get('pincode', sos_item.get('zone', ''))
                    patrol_table = _ddb().Table('rakshak-patrols')
                    available = patrol_table.scan(
                        FilterExpression=Attr('status').eq('Patrolling')
                    ).get('Items', [])
                    if available:
                        # Prefer matching zone; fall back to first available unit
                        matched = next(
                            (p for p in available if p.get('zone') == sos_zone), None
                        )
                        assigned = matched if matched else available[0]
                        patrol_id = assigned['patrol_id']
                        # Persist assignment on the SOS record
                        table.update_item(
                            Key={'sos_id': sos_id},
                            UpdateExpression='SET patrol_id = :pid',
                            ExpressionAttributeValues={':pid': patrol_id},
                        )

            new_patrol_status = PATROL_STATUS_MAP.get(new_sos_status)
            if patrol_id and new_patrol_status:
                _update_patrol(patrol_id, new_patrol_status)

            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps({'sos_id': sos_id, 'status': new_sos_status,
                                        'patrol_id': patrol_id})}

        # POST /sos/dispatch/{id}
        if method == 'POST' and '/sos/dispatch/' in path:
            sos_id = path.split('/sos/dispatch/')[-1]
            table.update_item(
                Key={'sos_id': sos_id},
                UpdateExpression='SET #s = :s, dispatched_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':s': 'dispatched', ':t': datetime.utcnow().isoformat() + 'Z'},
            )
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps({'sos_id': sos_id, 'status': 'dispatched'})}

        # PATCH /sos/resolve/{id}
        if method == 'PATCH' and '/sos/resolve/' in path:
            sos_id = path.split('/sos/resolve/')[-1]
            table.update_item(
                Key={'sos_id': sos_id},
                UpdateExpression='SET #s = :s, resolved_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':s': 'resolved', ':t': datetime.utcnow().isoformat() + 'Z'},
            )
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps({'sos_id': sos_id, 'status': 'resolved'})}

        return {'statusCode': 404, 'headers': CORS, 'body': json.dumps({'error': 'route not found'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS, 'body': json.dumps({'error': str(e)})}
'''

# ── Patrol handler — read-only, no simulation ─────────────────
PATROL_CODE = r'''
import json, os, boto3

REGION = 'ap-south-1'
KEY_ID = os.environ.get('RAKSHAK_AWS_ACCESS_KEY_ID')
SECRET  = os.environ.get('RAKSHAK_AWS_SECRET_ACCESS_KEY')

def _table():
    ddb = boto3.resource('dynamodb', region_name=REGION,
                         aws_access_key_id=KEY_ID, aws_secret_access_key=SECRET)
    return ddb.Table('rakshak-patrols')

CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
}

def lambda_handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')

    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS, 'body': ''}

    try:
        if method == 'GET':
            resp = _table().scan()
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps(resp.get('Items', []), default=str)}

        return {'statusCode': 405, 'headers': CORS,
                'body': json.dumps({'error': 'patrol status is managed via SOS lifecycle'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS, 'body': json.dumps({'error': str(e)})}
'''


# ── Deploy helper ─────────────────────────────────────────────
def deploy_lambda(name, code):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('lambda_function.py', code.strip())
    zb = buf.getvalue()

    lambda_client.update_function_code(FunctionName=name, ZipFile=zb)
    time.sleep(3)
    lambda_client.update_function_configuration(
        FunctionName=name, Environment=LAMBDA_ENV, Timeout=30, MemorySize=256)
    print(f'  ✅ Deployed {name}')


# ── Add new API route ─────────────────────────────────────────
def add_police_sos_route():
    sos_fn_arn = f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-sos-handler'
    uri = f'arn:aws:apigateway:{REGION}:lambda:path/2015-03-31/functions/{sos_fn_arn}/invocations'

    existing_intgs = {i.get('IntegrationUri', ''): i['IntegrationId']
                      for i in apigw.get_integrations(ApiId=API_ID)['Items']}
    intg_id = existing_intgs.get(uri)
    if not intg_id:
        resp = apigw.create_integration(
            ApiId=API_ID, IntegrationType='AWS_PROXY',
            IntegrationUri=uri, PayloadFormatVersion='2.0')
        intg_id = resp['IntegrationId']
        print(f'  ✅ Created integration {intg_id}')
    else:
        print(f'  ⏭️  Reusing integration {intg_id}')

    existing_routes = {r['RouteKey']: r['RouteId']
                       for r in apigw.get_routes(ApiId=API_ID)['Items']}

    for route_key in ['PATCH /police/sos/{id}/status', 'POST /sos/live']:
        if route_key not in existing_routes:
            apigw.create_route(ApiId=API_ID, RouteKey=route_key,
                               Target=f'integrations/{intg_id}')
            print(f'  ✅ Created route: {route_key}')
        else:
            print(f'  ⏭️  Route already exists: {route_key}')

    # Lambda invoke permission
    stmt_id = 'apigw-patch-police-sos-id-status'
    try:
        lambda_client.add_permission(
            FunctionName='rakshak-sos-handler', StatementId=stmt_id,
            Action='lambda:InvokeFunction', Principal='apigateway.amazonaws.com',
            SourceArn=f'arn:aws:execute-api:{REGION}:{ACCOUNT_ID}:{API_ID}/*/*',
        )
        print('  ✅ Lambda permission added')
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceConflictException':
            print('  ⏭️  Permission already exists')
        else:
            raise

    # Deploy API
    stages = apigw.get_stages(ApiId=API_ID)['Items']
    stage_name = stages[0]['StageName'] if stages else '$default'
    deploy = apigw.create_deployment(ApiId=API_ID)
    apigw.update_stage(ApiId=API_ID, StageName=stage_name,
                       DeploymentId=deploy['DeploymentId'])
    print(f'  ✅ API deployed to stage \'{stage_name}\'')


# ── Delete test SOS records ───────────────────────────────────
def delete_test_sos():
    sos_table = ddb.Table('rakshak-sos-alerts')
    test_ids = ['SOS-001', 'SOS-002', 'SOS-003', 'SOS001', 'SOS002', 'SOS003']
    for sos_id in test_ids:
        try:
            resp = sos_table.get_item(Key={'sos_id': sos_id})
            if 'Item' in resp:
                sos_table.delete_item(Key={'sos_id': sos_id})
                print(f'  🗑️  Deleted test record: {sos_id}')
            else:
                print(f'  ⏭️  Not found (already clean): {sos_id}')
        except Exception as e:
            print(f'  ⚠️  {sos_id}: {e}')


# ── Main ──────────────────────────────────────────────────────
print('\n=== 1. Deploy updated Lambdas ===')
deploy_lambda('rakshak-sos-handler',    SOS_CODE)
deploy_lambda('rakshak-patrol-handler', PATROL_CODE)

print('\n=== 2. Add PATCH /police/sos/{id}/status route ===')
add_police_sos_route()

print('\n=== 3. Delete test SOS records ===')
delete_test_sos()

print('\n✅ Done. Test:')
print(f'  curl -s https://{API_ID}.execute-api.{REGION}.amazonaws.com/sos/live | python3 -m json.tool')
print(f'  curl -s https://{API_ID}.execute-api.{REGION}.amazonaws.com/patrols | python3 -m json.tool')
