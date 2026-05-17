// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rakshak/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak/domain/models/time_context.dart';

void main() {
  group('TimeContext', () {
    test('should correctly calculate night time (20:00-05:59)', () {
      // Night time: 22:00
      final nightTime = DateTime(2024, 1, 15, 22, 30);
      final context = TimeContext.fromDateTime(nightTime);
      
      expect(context.hour, 22);
      expect(context.isNight, 1);
    });

    test('should correctly calculate day time (06:00-19:59)', () {
      // Day time: 14:00
      final dayTime = DateTime(2024, 1, 15, 14, 30);
      final context = TimeContext.fromDateTime(dayTime);
      
      expect(context.hour, 14);
      expect(context.isNight, 0);
    });

    test('should correctly identify weekend (Saturday)', () {
      // Saturday
      final saturday = DateTime(2024, 1, 13, 12, 0); // Jan 13, 2024 is Saturday
      final context = TimeContext.fromDateTime(saturday);
      
      expect(context.dayOfWeek, 6);
      expect(context.isWeekend, 1);
    });

    test('should correctly identify weekday (Monday)', () {
      // Monday
      final monday = DateTime(2024, 1, 15, 12, 0); // Jan 15, 2024 is Monday
      final context = TimeContext.fromDateTime(monday);
      
      expect(context.dayOfWeek, 1);
      expect(context.isWeekend, 0);
    });

    test('should convert to JSON correctly', () {
      final context = TimeContext(
        hour: 14,
        dayOfWeek: 3,
        isNight: 0,
        isWeekend: 0,
      );
      
      final json = context.toJson();
      
      expect(json['hour'], 14);
      expect(json['day_of_week'], 3);
      expect(json['is_night'], 0);
      expect(json['is_weekend'], 0);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak/domain/models/risk_assessment.dart';

void main() {
  group('RiskAssessment', () {
    test('should return correct color for Low risk', () {
      final assessment = RiskAssessment(
        riskLevel: 'Low',
        confidence: 0.85,
        probabilities: {'Low': 0.85, 'Medium': 0.10, 'High': 0.05},
        timestamp: DateTime.now(),
      );
      
      expect(assessment.displayColor, const Color(0xFF4CAF50));
    });

    test('should return correct color for Medium risk', () {
      final assessment = RiskAssessment(
        riskLevel: 'Medium',
        confidence: 0.75,
        probabilities: {'Low': 0.15, 'Medium': 0.75, 'High': 0.10},
        timestamp: DateTime.now(),
      );
      
      expect(assessment.displayColor, const Color(0xFFFFC107));
    });

    test('should return correct color for High risk', () {
      final assessment = RiskAssessment(
        riskLevel: 'High',
        confidence: 0.90,
        probabilities: {'Low': 0.05, 'Medium': 0.05, 'High': 0.90},
        timestamp: DateTime.now(),
      );
      
      expect(assessment.displayColor, const Color(0xFFF44336));
    });

    test('should correctly compare risk levels', () {
      final lowRisk = RiskAssessment(
        riskLevel: 'Low',
        confidence: 0.85,
        probabilities: {},
        timestamp: DateTime.now(),
      );
      
      final highRisk = RiskAssessment(
        riskLevel: 'High',
        confidence: 0.90,
        probabilities: {},
        timestamp: DateTime.now(),
      );
      
      expect(highRisk.isHigherRiskThan(lowRisk), true);
      expect(lowRisk.isHigherRiskThan(highRisk), false);
    });

    test('should parse from JSON correctly', () {
      final json = {
        'risk_level': 'High',
        'confidence': 0.92,
        'probabilities': {
          'Low': 0.03,
          'Medium': 0.05,
          'High': 0.92,
        },
      };
      
      final assessment = RiskAssessment.fromJson(json);
      
      expect(assessment.riskLevel, 'High');
      expect(assessment.confidence, 0.92);
      expect(assessment.probabilities['High'], 0.92);
    });
  });
}
"""Task 4: Seed test data into DynamoDB tables"""
import boto3, json, uuid, os
from datetime import datetime, timedelta
from decimal import Decimal

# Use the credentials that have DynamoDB access
# Set RAKSHAK_AWS_ACCESS_KEY_ID and RAKSHAK_AWS_SECRET_ACCESS_KEY as environment variables before running
ddb = boto3.resource(
    'dynamodb', region_name='ap-south-1',
    aws_access_key_id=os.environ["RAKSHAK_AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["RAKSHAK_AWS_SECRET_ACCESS_KEY"],
)

now = datetime.utcnow()

# ── rakshak-patrols ───────────────────────────────────────────
patrols_table = ddb.Table('rakshak-patrols')

patrol_items = [
    {"patrol_id": "P001", "officer": "Ravi Kumar",   "zone": "600001", "status": "Patrolling",  "vehicle": "TN01 AA 1234"},
    {"patrol_id": "P002", "officer": "Priya Nair",   "zone": "600034", "status": "AtScene",     "vehicle": "TN01 BB 5678"},
    {"patrol_id": "P003", "officer": "Arun Selvam",  "zone": "600041", "status": "Responding",  "vehicle": "TN01 CC 9012"},
]

print("=== Seeding rakshak-patrols ===")
for item in patrol_items:
    patrols_table.put_item(Item=item)
    print(f"  ✅ {item['patrol_id']} — {item['officer']} ({item['status']})")

# ── rakshak-sos-alerts ────────────────────────────────────────
sos_table = ddb.Table('rakshak-sos-alerts')

sos_items = [
    {
        "sos_id":     "SOS001",
        "location":   "Anna Nagar, Chennai",
        "lat":        "13.0850",
        "lng":        "80.2101",
        "status":     "active",
        "created_at": now.isoformat() + "Z",
        "reporter":   "Anonymous",
    },
    {
        "sos_id":     "SOS002",
        "location":   "T. Nagar, Chennai",
        "lat":        "13.0418",
        "lng":        "80.2341",
        "status":     "active",
        "created_at": (now - timedelta(minutes=12)).isoformat() + "Z",
        "reporter":   "Anonymous",
    },
]

print("\n=== Seeding rakshak-sos-alerts ===")
for item in sos_items:
    sos_table.put_item(Item=item)
    print(f"  ✅ {item['sos_id']} — {item['location']} ({item['status']})")

# ── rakshak-incidents ─────────────────────────────────────────
incidents_table = ddb.Table('rakshak-incidents')

pincodes = ["600001", "600034", "600041"]
statuses = ["approved", "approved", "approved", "pending", "pending"]

ML_DEFAULTS = {
    "hour":                      18,
    "day_of_week":               3,
    "is_weekend":                0,
    "is_night":                  0,
    "is_evening":                1,
    "is_rush_hour":              1,
    "reporting_delay_minutes":   10,
    "response_time_minutes":     8,
    "victim_age":                30,
    "signal_count_last_7d":      5,
    "signal_count_last_30d":     15,
    "signal_density_ratio":      Decimal("0.33"),
    "area_encoded":              1,
    "neighborhood_encoded":      1,
}

incident_rows = [
    {
        "pincode":     "600001",
        "description": "Suspicious activity near bus stop",
        "type":        "harassment",
    },
    {
        "pincode":     "600034",
        "description": "Unlit alley reported",
        "type":        "infrastructure",
    },
    {
        "pincode":     "600041",
        "description": "Drunk individual harassing commuters",
        "type":        "harassment",
    },
    {
        "pincode":     "600001",
        "description": "CCTV vandalism spotted",
        "type":        "vandalism",
    },
    {
        "pincode":     "600034",
        "description": "Street light outage on main road",
        "type":        "infrastructure",
    },
]

print("\n=== Seeding rakshak-incidents ===")
for i, row in enumerate(incident_rows):
    days_ago = i * 1  # spread over last 5 days
    ts = (now - timedelta(days=days_ago, hours=i)).isoformat() + "Z"
    item = {
        "incident_id": str(uuid.uuid4()),
        "created_at":  ts,
        "status":      statuses[i],
    }
    item.update(row)
    item.update(ML_DEFAULTS)
    incidents_table.put_item(Item=item)
    print(f"  ✅ {item['incident_id'][:8]}… {row['pincode']} {statuses[i]} ({row['type']})")

print("\n✅ All seed data inserted!")

# Verify counts
for name, table in [('patrols', patrols_table), ('sos-alerts', sos_table), ('incidents', incidents_table)]:
    count = table.scan(Select='COUNT')['Count']
    print(f"  rakshak-{name}: {count} items")
"""Task 2: Create 4 Lambda functions with inline code + explicit credentials env vars"""
import boto3, io, zipfile, json, os
from botocore.exceptions import ClientError

lambda_client = boto3.client('lambda', region_name='ap-south-1')

ROLE_ARN = "arn:aws:iam::468704514492:role/rakshak-lambda-role"

# Pass through credentials so Lambdas can access new DynamoDB tables
# Set RAKSHAK_AWS_ACCESS_KEY_ID and RAKSHAK_AWS_SECRET_ACCESS_KEY as environment variables before running
LAMBDA_ENV = {
    "Variables": {
        "AWS_REGION_OVERRIDE": "ap-south-1",
        "RAKSHAK_AWS_ACCESS_KEY_ID": os.environ["RAKSHAK_AWS_ACCESS_KEY_ID"],
        "RAKSHAK_AWS_SECRET_ACCESS_KEY": os.environ["RAKSHAK_AWS_SECRET_ACCESS_KEY"],
    }
}

# ─────────────────────────────────────────────────────────────
# LAMBDA 1: rakshak-score-refresh
# ─────────────────────────────────────────────────────────────
SCORE_REFRESH_CODE = r'''
import json, os, boto3
from datetime import datetime

REGION = 'ap-south-1'
KEY_ID = os.environ.get('RAKSHAK_AWS_ACCESS_KEY_ID')
SECRET  = os.environ.get('RAKSHAK_AWS_SECRET_ACCESS_KEY')

CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
}

ENDPOINT = 'rakshak-risk-endpoint'


def build_features(zone):
    hour = zone.get('hour', 20)
    # Parse hour from ISO timestamp if provided
    time_str = zone.get('time', '')
    if time_str:
        try:
            if 'T' in time_str:
                hour = int(time_str.split('T')[1].split(':')[0])
            elif ':' in time_str:
                hour = int(time_str.split(':')[0])
        except Exception:
            hour = 20

    day = zone.get('day_of_week', datetime.utcnow().weekday())
    is_weekend   = 1 if day in [5, 6] else 0
    is_night     = 1 if (hour >= 22 or hour <= 5) else 0
    is_evening   = 1 if (17 <= hour <= 21) else 0
    is_rush_hour = 1 if hour in [8, 9, 17, 18, 19] else 0

    pincode = int(zone.get('pincode', 600001))
    units   = int(zone.get('units', 1))

    # Derive signal counts from units available (proxy for now)
    signal_7d     = max(1, 10 - units * 2)
    signal_30d    = max(1, signal_7d * 4)
    density_ratio = round(signal_7d / signal_30d, 4)

    # Area encoding based on pincode
    area_encoded          = (pincode % 100) % 15
    neighborhood_encoded  = (pincode % 1000) % 20

    return [
        13.0827,           # latitude (Chennai center default)
        80.2707,           # longitude
        float(pincode),    # pincode
        float(hour),       # hour
        float(day),        # day_of_week
        float(is_weekend),
        float(is_night),
        float(is_evening),
        float(is_rush_hour),
        10.0,              # reporting_delay_minutes
        8.0,               # response_time_minutes
        25.0,              # victim_age
        float(signal_7d),
        float(signal_30d),
        float(density_ratio),
        float(area_encoded),
        float(neighborhood_encoded),
    ]


def lambda_handler(event, context):
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS, 'body': ''}

    try:
        body  = json.loads(event.get('body', '{}') or '{}')
        zones = body.get('zones', [])
        results = []

        sagemaker_runtime = boto3.client(
            'sagemaker-runtime', region_name=REGION,
            aws_access_key_id=KEY_ID, aws_secret_access_key=SECRET,
        )

        for zone in zones:
            pincode_str = str(zone.get('pincode', '600001'))

            try:
                features = build_features(zone)
                payload  = json.dumps({"instances": [features]})

                response = sagemaker_runtime.invoke_endpoint(
                    EndpointName=ENDPOINT,
                    ContentType='application/json',
                    Body=payload,
                )
                result = json.loads(response['Body'].read().decode())

                # Unwrap nested lists: [[0.73]] → 0.73
                while isinstance(result, list):
                    result = result[0]
                if isinstance(result, dict):
                    result = result.get('predictions', result.get('score', 0.5))
                    while isinstance(result, list):
                        result = result[0]

                safe_score = float(result)

            except Exception as e:
                print(f"SageMaker error for pincode {pincode_str}: {type(e).__name__}: {e}")
                safe_score = 0.5

            # Map score to risk level
            if safe_score >= 0.6:
                risk_level = 'LOW'
            elif safe_score >= 0.3:
                risk_level = 'MEDIUM'
            else:
                risk_level = 'HIGH'

            results.append({
                'pincode':    pincode_str,
                'safe_score': round(safe_score, 4),
                'risk_level': risk_level,
            })

        return {'statusCode': 200, 'headers': CORS, 'body': json.dumps(results)}
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS, 'body': json.dumps({'error': str(e)})}
'''

# ─────────────────────────────────────────────────────────────
# LAMBDA 2: rakshak-reports-handler
# ─────────────────────────────────────────────────────────────
REPORTS_CODE = r'''
import json, os, uuid, boto3
from boto3.dynamodb.conditions import Attr
from datetime import datetime

REGION = 'ap-south-1'
KEY_ID = os.environ.get('RAKSHAK_AWS_ACCESS_KEY_ID')
SECRET  = os.environ.get('RAKSHAK_AWS_SECRET_ACCESS_KEY')

def _table():
    ddb = boto3.resource('dynamodb', region_name=REGION,
                         aws_access_key_id=KEY_ID, aws_secret_access_key=SECRET)
    return ddb.Table('rakshak-incidents')

CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
}

def lambda_handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path   = event.get('rawPath', '')

    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS, 'body': ''}

    try:
        table = _table()

        # POST /reports/submit
        if method == 'POST' and path.endswith('/reports/submit'):
            body = json.loads(event.get('body', '{}') or '{}')
            item = {
                'incident_id': str(uuid.uuid4()),
                'created_at':  datetime.utcnow().isoformat() + 'Z',
                'status':      'pending',
            }
            item.update(body)
            table.put_item(Item=item)
            return {'statusCode': 201, 'headers': CORS, 'body': json.dumps(item)}

        # GET /reports
        if method == 'GET':
            resp  = table.scan()
            items = resp.get('Items', [])
            return {'statusCode': 200, 'headers': CORS, 'body': json.dumps(items, default=str)}

        # PATCH /reports/approve/{id}
        if method == 'PATCH' and '/reports/approve/' in path:
            incident_id = path.split('/reports/approve/')[-1]
            scan = table.scan(FilterExpression=Attr('incident_id').eq(incident_id))
            items = scan.get('Items', [])
            if not items:
                return {'statusCode': 404, 'headers': CORS, 'body': json.dumps({'error': 'not found'})}
            table.update_item(
                Key={'incident_id': incident_id, 'created_at': items[0]['created_at']},
                UpdateExpression='SET #s = :s, approved_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':s': 'approved', ':t': datetime.utcnow().isoformat() + 'Z'},
            )
            return {'statusCode': 200, 'headers': CORS, 'body': json.dumps({'incident_id': incident_id, 'status': 'approved'})}

        # PATCH /reports/reject/{id}
        if method == 'PATCH' and '/reports/reject/' in path:
            incident_id = path.split('/reports/reject/')[-1]
            scan = table.scan(FilterExpression=Attr('incident_id').eq(incident_id))
            items = scan.get('Items', [])
            if not items:
                return {'statusCode': 404, 'headers': CORS, 'body': json.dumps({'error': 'not found'})}
            table.update_item(
                Key={'incident_id': incident_id, 'created_at': items[0]['created_at']},
                UpdateExpression='SET #s = :s, rejected_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':s': 'rejected', ':t': datetime.utcnow().isoformat() + 'Z'},
            )
            return {'statusCode': 200, 'headers': CORS, 'body': json.dumps({'incident_id': incident_id, 'status': 'rejected'})}

        return {'statusCode': 404, 'headers': CORS, 'body': json.dumps({'error': 'route not found'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS, 'body': json.dumps({'error': str(e)})}
'''

# ─────────────────────────────────────────────────────────────
# LAMBDA 3: rakshak-sos-handler
# ─────────────────────────────────────────────────────────────
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

# SOS status → patrol status mapping (driven by SOS lifecycle only)
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

        # GET /sos/live — only active/dispatched alerts from the last 24 hours
        if method == 'GET' and path.endswith('/sos/live'):
            cutoff = (datetime.utcnow() - timedelta(hours=24)).isoformat() + 'Z'
            resp = table.scan(
                FilterExpression=Attr('status').is_in(['active', 'dispatched']) &
                                 Attr('created_at').gte(cutoff)
            )
            return {'statusCode': 200, 'headers': CORS, 'body': json.dumps(resp.get('Items', []), default=str)}

        # PATCH /police/sos/{id}/status — officer updates SOS; cascades to patrol status
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
                        matched = next(
                            (p for p in available if p.get('zone') == sos_zone), None
                        )
                        assigned = matched if matched else available[0]
                        patrol_id = assigned['patrol_id']
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
            return {'statusCode': 200, 'headers': CORS, 'body': json.dumps({'sos_id': sos_id, 'status': 'dispatched'})}

        # PATCH /sos/resolve/{id}
        if method == 'PATCH' and '/sos/resolve/' in path:
            sos_id = path.split('/sos/resolve/')[-1]
            table.update_item(
                Key={'sos_id': sos_id},
                UpdateExpression='SET #s = :s, resolved_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':s': 'resolved', ':t': datetime.utcnow().isoformat() + 'Z'},
            )
            return {'statusCode': 200, 'headers': CORS, 'body': json.dumps({'sos_id': sos_id, 'status': 'resolved'})}

        return {'statusCode': 404, 'headers': CORS, 'body': json.dumps({'error': 'route not found'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS, 'body': json.dumps({'error': str(e)})}
'''

# ─────────────────────────────────────────────────────────────
# LAMBDA 4: rakshak-patrol-handler
# Patrol status changes ONLY via SOS lifecycle (PATCH /police/sos/{id}/status).
# This handler is read-only; no simulation or autonomous status mutation.
# ─────────────────────────────────────────────────────────────
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
        # GET /patrols — return current patrol state; status reflects last SOS action
        if method == 'GET':
            resp = _table().scan()
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps(resp.get('Items', []), default=str)}

        return {'statusCode': 405, 'headers': CORS,
                'body': json.dumps({'error': 'patrol status is managed via SOS lifecycle'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS, 'body': json.dumps({'error': str(e)})}
'''


def create_or_update_lambda(name, code, description):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('lambda_function.py', code.strip())
    zip_bytes = buf.getvalue()

    try:
        resp = lambda_client.create_function(
            FunctionName=name,
            Runtime='python3.12',
            Role=ROLE_ARN,
            Handler='lambda_function.lambda_handler',
            Code={'ZipFile': zip_bytes},
            Description=description,
            Timeout=30,
            MemorySize=256,
            Environment=LAMBDA_ENV,
        )
        arn = resp['FunctionArn']
        print(f"✅ Created Lambda: {name}")
        return arn
    except ClientError as e:
        if e.response['Error']['Code'] in ('ResourceConflictException', 'ResourceNotFoundException'):
            # Update code
            lambda_client.update_function_code(FunctionName=name, ZipFile=zip_bytes)
            # Update config
            import time; time.sleep(2)
            lambda_client.update_function_configuration(
                FunctionName=name,
                Environment=LAMBDA_ENV,
                Timeout=30,
                MemorySize=256,
            )
            resp = lambda_client.get_function_configuration(FunctionName=name)
            arn = resp['FunctionArn']
            print(f"🔄 Updated Lambda: {name}")
            return arn
        else:
            raise


arns = {}
arns['rakshak-score-refresh']   = create_or_update_lambda('rakshak-score-refresh',   SCORE_REFRESH_CODE, 'Refresh zone risk scores via SageMaker')
arns['rakshak-reports-handler'] = create_or_update_lambda('rakshak-reports-handler', REPORTS_CODE,       'CRUD for incident reports')
arns['rakshak-sos-handler']     = create_or_update_lambda('rakshak-sos-handler',     SOS_CODE,           'SOS alert management')
arns['rakshak-patrol-handler']  = create_or_update_lambda('rakshak-patrol-handler',  PATROL_CODE,        'Patrol unit management')

with open('/tmp/rakshak_arns.json', 'w') as f:
    json.dump(arns, f, indent=2)

print("\nAll Lambda ARNs:")
print(json.dumps(arns, indent=2))
"""Task 1: Create DynamoDB tables (skip if already exists)"""
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.client('dynamodb', region_name='ap-south-1')

tables = [
    {
        "TableName": "rakshak-incidents",
        "KeySchema": [
            {"AttributeName": "incident_id", "KeyType": "HASH"},
            {"AttributeName": "created_at", "KeyType": "RANGE"},
        ],
        "AttributeDefinitions": [
            {"AttributeName": "incident_id", "AttributeType": "S"},
            {"AttributeName": "created_at", "AttributeType": "S"},
        ],
        "BillingMode": "PAY_PER_REQUEST",
    },
    {
        "TableName": "rakshak-patrols",
        "KeySchema": [{"AttributeName": "patrol_id", "KeyType": "HASH"}],
        "AttributeDefinitions": [{"AttributeName": "patrol_id", "AttributeType": "S"}],
        "BillingMode": "PAY_PER_REQUEST",
    },
    {
        "TableName": "rakshak-zones",
        "KeySchema": [{"AttributeName": "pincode", "KeyType": "HASH"}],
        "AttributeDefinitions": [{"AttributeName": "pincode", "AttributeType": "S"}],
        "BillingMode": "PAY_PER_REQUEST",
    },
]

for table_def in tables:
    name = table_def["TableName"]
    try:
        dynamodb.create_table(**table_def)
        print(f"✅ Created table: {name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            print(f"⏭️  Table already exists (skipped): {name}")
        else:
            raise

# Wait for tables to be active
waiter = dynamodb.get_waiter('table_exists')
for table_def in tables:
    name = table_def["TableName"]
    print(f"⏳ Waiting for {name} to be ACTIVE...")
    waiter.wait(TableName=name)
    print(f"✅ {name} is ACTIVE")
"""Task 3: Add routes to existing API Gateway aksdwfbnn5"""
import boto3, json, time
from botocore.exceptions import ClientError

apigw = boto3.client('apigatewayv2', region_name='ap-south-1')
lam   = boto3.client('lambda',       region_name='ap-south-1')

API_ID     = 'aksdwfbnn5'
ACCOUNT_ID = '468704514492'
REGION     = 'ap-south-1'

# Load ARNs
with open('/tmp/rakshak_arns.json') as f:
    ARNS = json.load(f)

# Also add sos-handler since it was created in task 2
ARNS['rakshak-sos-handler']    = f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-sos-handler'
ARNS['rakshak-patrol-handler'] = f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-patrol-handler'

# Route → Lambda name mapping
ROUTES = [
    ('POST',  '/score/refresh',          'rakshak-score-refresh'),
    ('POST',  '/reports/submit',         'rakshak-reports-handler'),
    ('GET',   '/reports',                'rakshak-reports-handler'),
    ('PATCH', '/reports/approve/{id}',   'rakshak-reports-handler'),
    ('PATCH', '/reports/reject/{id}',    'rakshak-reports-handler'),
    ('GET',   '/sos/live',               'rakshak-sos-handler'),
    ('POST',  '/sos/dispatch/{id}',      'rakshak-sos-handler'),
    ('PATCH', '/sos/resolve/{id}',       'rakshak-sos-handler'),
    ('GET',   '/patrols',                'rakshak-patrol-handler'),
    ('PATCH', '/patrols/{id}/status',    'rakshak-patrol-handler'),
]

# OPTIONS paths (CORS preflight)
OPTIONS_PATHS = set(path for _, path, _ in ROUTES)

# ── Step 1: fetch existing integrations ──────────────────────
existing_integrations = {}
try:
    pager = apigw.get_paginator('get_integrations')
    for page in pager.paginate(ApiId=API_ID):
        for intg in page['Items']:
            uri = intg.get('IntegrationUri', '')
            existing_integrations[uri] = intg['IntegrationId']
except Exception as e:
    print(f"Warning getting integrations: {e}")

# ── Step 2: fetch existing routes ────────────────────────────
existing_routes = {}
try:
    pager = apigw.get_paginator('get_routes')
    for page in pager.paginate(ApiId=API_ID):
        for r in page['Items']:
            key = r['RouteKey']  # e.g. "POST /score/refresh"
            existing_routes[key] = r['RouteId']
except Exception as e:
    print(f"Warning getting routes: {e}")

print(f"Existing routes: {list(existing_routes.keys())}")


def get_or_create_integration(lambda_name):
    fn_arn = ARNS[lambda_name]
    uri    = f'arn:aws:apigateway:{REGION}:lambda:path/2015-03-31/functions/{fn_arn}/invocations'

    if uri in existing_integrations:
        intg_id = existing_integrations[uri]
        print(f"  ⏭️  Reusing integration {intg_id} for {lambda_name}")
        return intg_id

    resp = apigw.create_integration(
        ApiId=API_ID,
        IntegrationType='AWS_PROXY',
        IntegrationUri=uri,
        PayloadFormatVersion='2.0',
    )
    intg_id = resp['IntegrationId']
    existing_integrations[uri] = intg_id
    print(f"  ✅ Created integration {intg_id} for {lambda_name}")
    return intg_id


def get_or_create_route(method, path, intg_id):
    route_key = f'{method} {path}'
    if route_key in existing_routes:
        print(f"  ⏭️  Route already exists: {route_key}")
        return existing_routes[route_key]

    resp = apigw.create_route(
        ApiId=API_ID,
        RouteKey=route_key,
        Target=f'integrations/{intg_id}',
    )
    route_id = resp['RouteId']
    existing_routes[route_key] = route_id
    print(f"  ✅ Created route: {route_key} → {route_id}")
    return route_id


def ensure_lambda_permission(lambda_name, method, path):
    fn_name    = lambda_name
    stmt_id    = f'apigw-{method.lower()}-{path.replace("/","-").replace("{","").replace("}","")}'
    source_arn = f'arn:aws:execute-api:{REGION}:{ACCOUNT_ID}:{API_ID}/*/*'

    try:
        lam.add_permission(
            FunctionName=fn_name,
            StatementId=stmt_id,
            Action='lambda:InvokeFunction',
            Principal='apigateway.amazonaws.com',
            SourceArn=source_arn,
        )
        print(f"  ✅ Added invoke permission for {fn_name}")
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceConflictException':
            pass  # already exists
        else:
            print(f"  ⚠️  Permission error for {fn_name}: {e}")


# ── Step 3: create routes and integrations ───────────────────
lambda_intg_cache = {}

for method, path, lambda_name in ROUTES:
    print(f"\n▶ {method} {path} → {lambda_name}")

    if lambda_name not in lambda_intg_cache:
        lambda_intg_cache[lambda_name] = get_or_create_integration(lambda_name)
    intg_id = lambda_intg_cache[lambda_name]

    get_or_create_route(method, path, intg_id)
    ensure_lambda_permission(lambda_name, method, path)

# ── Step 4: OPTIONS routes for CORS ─────────────────────────
# Use score-refresh integration as a dummy — API GW returns CORS headers from Lambda
print("\n▶ OPTIONS routes for CORS preflight")
# For HTTP API v2, a catch-all OPTIONS route is cleanest
options_key = 'OPTIONS /{proxy+}'
if options_key not in existing_routes:
    # Use any integration (score-refresh handles OPTIONS inline)
    dummy_intg = lambda_intg_cache.get('rakshak-score-refresh') or list(lambda_intg_cache.values())[0]
    try:
        resp = apigw.create_route(
            ApiId=API_ID,
            RouteKey=options_key,
            Target=f'integrations/{dummy_intg}',
        )
        print(f"  ✅ Created catch-all OPTIONS route → {resp['RouteId']}")
    except ClientError as e:
        print(f"  OPTIONS: {e}")
else:
    print(f"  ⏭️  OPTIONS route already exists")

# ── Step 5: deploy the API ────────────────────────────────────
print("\n▶ Deploying API...")
try:
    # Find existing $default stage
    stages = apigw.get_stages(ApiId=API_ID)['Items']
    stage_name = stages[0]['StageName'] if stages else '$default'
    print(f"  Stage: {stage_name}")

    deploy = apigw.create_deployment(ApiId=API_ID)
    deploy_id = deploy['DeploymentId']
    print(f"  ✅ Created deployment: {deploy_id}")

    apigw.update_stage(
        ApiId=API_ID,
        StageName=stage_name,
        DeploymentId=deploy_id,
    )
    print(f"  ✅ Stage '{stage_name}' updated to deployment {deploy_id}")
except Exception as e:
    print(f"  Deploy note: {e}")

print("\n✅ API Gateway setup complete!")
print(f"Base URL: https://{API_ID}.execute-api.{REGION}.amazonaws.com")
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
"""Task 3: Add routes to existing API Gateway using default profile credentials"""
import boto3, json, time
from botocore.exceptions import ClientError

session = boto3.Session(profile_name='default')
apigw   = session.client('apigatewayv2', region_name='ap-south-1')
lam     = session.client('lambda',       region_name='ap-south-1')

API_ID     = 'aksdwfbnn5'
ACCOUNT_ID = '468704514492'
REGION     = 'ap-south-1'

ARNS = {
    'rakshak-score-refresh':   f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-score-refresh',
    'rakshak-reports-handler': f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-reports-handler',
    'rakshak-sos-handler':     f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-sos-handler',
    'rakshak-patrol-handler':  f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:rakshak-patrol-handler',
}

ROUTES = [
    ('POST',  '/score/refresh',          'rakshak-score-refresh'),
    ('POST',  '/reports/submit',         'rakshak-reports-handler'),
    ('GET',   '/reports',                'rakshak-reports-handler'),
    ('PATCH', '/reports/approve/{id}',   'rakshak-reports-handler'),
    ('PATCH', '/reports/reject/{id}',    'rakshak-reports-handler'),
    ('POST',  '/sos/live',               'rakshak-sos-handler'),
    ('GET',   '/sos/live',               'rakshak-sos-handler'),
    ('POST',  '/sos/dispatch/{id}',      'rakshak-sos-handler'),
    ('PATCH', '/sos/resolve/{id}',       'rakshak-sos-handler'),
    ('GET',   '/patrols',                'rakshak-patrol-handler'),
    ('PATCH', '/patrols/{id}/status',    'rakshak-patrol-handler'),
]

# ── Fetch existing state ──────────────────────────────────────
existing_integrations = {}  # uri → intg_id
for intg in apigw.get_integrations(ApiId=API_ID)['Items']:
    uri = intg.get('IntegrationUri', '')
    existing_integrations[uri] = intg['IntegrationId']

existing_routes = {}  # "METHOD /path" → route_id
for r in apigw.get_routes(ApiId=API_ID)['Items']:
    existing_routes[r['RouteKey']] = r['RouteId']

print(f"Existing integrations: {len(existing_integrations)}")
print(f"Existing routes: {list(existing_routes.keys())}")


def get_or_create_integration(lambda_name):
    fn_arn = ARNS[lambda_name]
    uri    = f'arn:aws:apigateway:{REGION}:lambda:path/2015-03-31/functions/{fn_arn}/invocations'

    if uri in existing_integrations:
        intg_id = existing_integrations[uri]
        print(f"  ⏭️  Reusing integration {intg_id} for {lambda_name}")
        return intg_id

    resp = apigw.create_integration(
        ApiId=API_ID,
        IntegrationType='AWS_PROXY',
        IntegrationUri=uri,
        PayloadFormatVersion='2.0',
    )
    intg_id = resp['IntegrationId']
    existing_integrations[uri] = intg_id
    print(f"  ✅ Created integration {intg_id} for {lambda_name}")
    return intg_id


def get_or_create_route(method, path, intg_id):
    route_key = f'{method} {path}'
    if route_key in existing_routes:
        print(f"  ⏭️  Route exists: {route_key}")
        return existing_routes[route_key]

    resp = apigw.create_route(
        ApiId=API_ID,
        RouteKey=route_key,
        Target=f'integrations/{intg_id}',
    )
    route_id = resp['RouteId']
    existing_routes[route_key] = route_id
    print(f"  ✅ Created route: {route_key} → {route_id}")
    return route_id


def ensure_lambda_permission(lambda_name, method, path):
    # Sanitise statement ID
    stmt_id = f'apigw-{method.lower()}{path.replace("/","-").replace("{","").replace("}","").replace("--","-")}'
    stmt_id = stmt_id[:100]
    source_arn = f'arn:aws:execute-api:{REGION}:{ACCOUNT_ID}:{API_ID}/*/*'

    try:
        lam.add_permission(
            FunctionName=lambda_name,
            StatementId=stmt_id,
            Action='lambda:InvokeFunction',
            Principal='apigateway.amazonaws.com',
            SourceArn=source_arn,
        )
    except ClientError as e:
        if e.response['Error']['Code'] != 'ResourceConflictException':
            print(f"  ⚠️  Permission {lambda_name}: {e.response['Error']['Code']}")


# ── Create routes ─────────────────────────────────────────────
lambda_intg_cache = {}

for method, path, lambda_name in ROUTES:
    print(f"\n▶ {method} {path} → {lambda_name}")
    if lambda_name not in lambda_intg_cache:
        lambda_intg_cache[lambda_name] = get_or_create_integration(lambda_name)
    intg_id = lambda_intg_cache[lambda_name]
    get_or_create_route(method, path, intg_id)
    ensure_lambda_permission(lambda_name, method, path)

# ── Catch-all OPTIONS route ───────────────────────────────────
print("\n▶ OPTIONS /{proxy+} catch-all")
options_key = 'OPTIONS /{proxy+}'
if options_key not in existing_routes:
    dummy_intg = list(lambda_intg_cache.values())[0]
    try:
        resp = apigw.create_route(
            ApiId=API_ID,
            RouteKey=options_key,
            Target=f'integrations/{dummy_intg}',
        )
        print(f"  ✅ Created: {options_key} → {resp['RouteId']}")
    except Exception as e:
        print(f"  OPTIONS: {e}")
else:
    print(f"  ⏭️  Already exists")

# ── Deploy ────────────────────────────────────────────────────
print("\n▶ Deploying API...")
stages = apigw.get_stages(ApiId=API_ID)['Items']
stage_name = stages[0]['StageName'] if stages else '$default'

deploy = apigw.create_deployment(ApiId=API_ID)
deploy_id = deploy['DeploymentId']
apigw.update_stage(ApiId=API_ID, StageName=stage_name, DeploymentId=deploy_id)
print(f"  ✅ Deployed to stage '{stage_name}' (deployment {deploy_id})")

# ── Final route list ──────────────────────────────────────────
print("\n══ Final route list ══")
all_routes = apigw.get_routes(ApiId=API_ID)['Items']
for r in sorted(all_routes, key=lambda x: x['RouteKey']):
    print(f"  {r['RouteKey']}")

print(f"\n✅ Done — Base URL: https://{API_ID}.execute-api.{REGION}.amazonaws.com")
"""
Adds POST /sos/cancelled handling to the existing rakshak-sos-handler Lambda.

This script:
1. Fetches the current Lambda code
2. Patches it to handle POST /sos/cancelled
3. Redeploys the Lambda
4. Adds the API Gateway route POST /sos/cancelled → existing im4k71v integration
"""
import boto3, json, io, zipfile, base64
from botocore.exceptions import ClientError

REGION      = 'ap-south-1'
LAMBDA_NAME = 'rakshak-sos-handler'
API_ID      = 'aksdwfbnn5'
INTEGRATION = 'im4k71v'   # existing SOS handler integration

lambda_client = boto3.client('lambda', region_name=REGION)
apigw         = boto3.client('apigatewayv2', region_name=REGION)

# ── New Lambda code with /sos/cancelled added ─────────────────────────────────
NEW_SOS_CODE = r'''
import json, os, boto3
from boto3.dynamodb.conditions import Attr
from datetime import datetime

REGION = 'ap-south-1'

def _table():
    ddb = boto3.resource('dynamodb', region_name=REGION)
    return ddb.Table('rakshak-sos-alerts')

CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
}

def lambda_handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path   = event.get('rawPath', '')

    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS, 'body': ''}

    try:
        table = _table()

        # GET /sos/live
        if method == 'GET' and path.endswith('/sos/live'):
            resp  = table.scan(FilterExpression=Attr('status').eq('active'))
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps(resp.get('Items', []), default=str)}

        # POST /sos/live  — create new SOS alert
        if method == 'POST' and path.endswith('/sos/live'):
            import uuid
            body = json.loads(event.get('body', '{}') or '{}')
            sos_id = f"SOS-{uuid.uuid4().hex[:8].upper()}"
            item = {
                'sos_id':     sos_id,
                'status':     'active',
                'created_at': datetime.utcnow().isoformat() + 'Z',
            }
            # Copy all fields from body (lat, lng, latitude, longitude, pincode, etc.)
            for k, v in body.items():
                if k not in item:
                    item[k] = v
            # Ensure zone_name = pincode if not set
            if 'pincode' in item and 'zone_name' not in item:
                item['zone_name'] = str(item['pincode'])
            table.put_item(Item=item)
            return {'statusCode': 201, 'headers': CORS,
                    'body': json.dumps({'sos_id': sos_id, 'status': 'active'})}

        # POST /sos/dispatch/{id}
        if method == 'POST' and '/sos/dispatch/' in path:
            sos_id = path.split('/sos/dispatch/')[-1]
            table.update_item(
                Key={'sos_id': sos_id},
                UpdateExpression='SET #s = :s, dispatched_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':s': 'dispatched',
                                           ':t': datetime.utcnow().isoformat() + 'Z'},
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
                ExpressionAttributeValues={':s': 'resolved',
                                           ':t': datetime.utcnow().isoformat() + 'Z'},
            )
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps({'sos_id': sos_id, 'status': 'resolved'})}

        # POST /sos/cancelled  — citizen cancels their own SOS
        if method == 'POST' and path.endswith('/sos/cancelled'):
            body       = json.loads(event.get('body', '{}') or '{}')
            sos_id     = body.get('sos_id')
            user_phone = body.get('user_phone', '')
            pincode    = body.get('pincode', '')

            if not sos_id:
                return {'statusCode': 400, 'headers': CORS,
                        'body': json.dumps({'error': 'sos_id required'})}

            table.update_item(
                Key={'sos_id': sos_id},
                UpdateExpression='SET #s = :s, user_phone = :p, cancelled_at = :t',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={
                    ':s': 'cancelled',
                    ':p': user_phone,
                    ':t': datetime.utcnow().isoformat() + 'Z',
                },
            )
            return {'statusCode': 200, 'headers': CORS,
                    'body': json.dumps({'message': 'SOS cancelled', 'sos_id': sos_id})}

        return {'statusCode': 404, 'headers': CORS,
                'body': json.dumps({'error': 'route not found'})}

    except Exception as e:
        return {'statusCode': 500, 'headers': CORS,
                'body': json.dumps({'error': str(e)})}
'''


def deploy_lambda():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('lambda_function.py', NEW_SOS_CODE.strip())
    zip_bytes = buf.getvalue()

    lambda_client.update_function_code(
        FunctionName=LAMBDA_NAME,
        ZipFile=zip_bytes,
    )
    print(f'✅ Updated Lambda: {LAMBDA_NAME}')


def add_api_route():
    # Check if route already exists
    routes = apigw.get_routes(ApiId=API_ID)['Items']
    for r in routes:
        if 'cancelled' in r.get('RouteKey', '').lower():
            print(f'ℹ️  Route already exists: {r["RouteKey"]}')
            return r['RouteId']

    # Add POST /sos/cancelled → existing SOS handler integration
    resp = apigw.create_route(
        ApiId=API_ID,
        RouteKey='POST /sos/cancelled',
        Target=f'integrations/{INTEGRATION}',
    )
    route_id = resp['RouteId']
    print(f'✅ Created route: POST /sos/cancelled (RouteId: {route_id})')

    # Grant API Gateway permission to invoke the Lambda
    try:
        lambda_client.add_permission(
            FunctionName=LAMBDA_NAME,
            StatementId='apigw-sos-cancelled',
            Action='lambda:InvokeFunction',
            Principal='apigateway.amazonaws.com',
            SourceArn=f'arn:aws:execute-api:{REGION}:468704514492:{API_ID}/*/*/sos/cancelled',
        )
        print('✅ Lambda invoke permission added')
    except ClientError as e:
        if 'ResourceConflictException' in str(e):
            print('ℹ️  Lambda permission already exists')
        else:
            print(f'⚠️  Permission error: {e}')

    return route_id


if __name__ == '__main__':
    import time
    print('=== Deploying /sos/cancelled ===')
    deploy_lambda()
    time.sleep(3)
    add_api_route()
    print('\n=== Testing /sos/cancelled ===')
    import urllib.request
    test = urllib.request.Request(
        'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com/sos/cancelled',
        data=json.dumps({'sos_id': 'TEST-CANCEL-001', 'user_phone': '+91-9999999999'}).encode(),
        headers={'Content-Type': 'application/json'},
        method='POST',
    )
    try:
        with urllib.request.urlopen(test, timeout=10) as r:
            print('Response:', r.read().decode())
    except Exception as e:
        print('Test error (expected if sos_id not in DB):', e)
"""Task 2: Create 4 Lambda functions with inline code"""
import boto3, json, textwrap
from botocore.exceptions import ClientError

lambda_client = boto3.client('lambda', region_name='ap-south-1')

ROLE_ARN = "arn:aws:iam::468704514492:role/service-role/AmazonSageMaker-ExecutionRole-20260406T145594"

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

# ─────────────────────────────────────────────────────────────
# LAMBDA 1: rakshak-score-refresh
# ─────────────────────────────────────────────────────────────
SCORE_REFRESH_CODE = '''
import json
import boto3
from datetime import datetime

lambda_client = boto3.client("lambda", region_name="ap-south-1")

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

def lambda_handler(event, context):
    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        body = json.loads(event.get("body", "{}") or "{}")
        zones = body.get("zones", [])
        results = []

        now = datetime.utcnow()
        dow = now.weekday()  # 0=Mon, 6=Sun
        is_weekend = 1 if dow >= 5 else 0

        for zone in zones:
            pincode = zone.get("pincode", "600001")
            time_str = zone.get("time", "12:00")
            hour = int(time_str.split(":")[0])

            is_night = 1 if hour < 6 or hour >= 22 else 0
            is_evening = 1 if 17 <= hour < 22 else 0
            is_rush_hour = 1 if (7 <= hour <= 9) or (17 <= hour <= 19) else 0

            payload = {
                "pincode": pincode,
                "hour": hour,
                "day_of_week": dow,
                "is_weekend": is_weekend,
                "is_night": is_night,
                "is_evening": is_evening,
                "is_rush_hour": is_rush_hour,
                "reporting_delay_minutes": 10,
                "response_time_minutes": 8,
                "victim_age": 30,
                "signal_count_last_7d": 5,
                "signal_count_last_30d": 15,
                "signal_density_ratio": 0.33,
                "area_encoded": 1,
                "neighborhood_encoded": 1,
            }

            try:
                resp = lambda_client.invoke(
                    FunctionName="rakshak-test-inference",
                    InvocationType="RequestResponse",
                    Payload=json.dumps(payload),
                )
                raw = json.loads(resp["Payload"].read())
                # Handle both direct score and body-wrapped score
                if isinstance(raw, dict):
                    score = raw.get("safe_score") or raw.get("score") or 0.5
                    if "body" in raw:
                        inner = json.loads(raw["body"]) if isinstance(raw["body"], str) else raw["body"]
                        score = inner.get("safe_score") or inner.get("score") or score
                else:
                    score = float(raw) if raw else 0.5
            except Exception as e:
                score = 0.5  # default on inference error

            score = float(score)
            if score >= 0.7:
                risk_level = "HIGH"
            elif score >= 0.4:
                risk_level = "MEDIUM"
            else:
                risk_level = "LOW"

            results.append({
                "pincode": pincode,
                "safe_score": round(score, 4),
                "risk_level": risk_level,
            })

        return {
            "statusCode": 200,
            "headers": CORS,
            "body": json.dumps(results),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": CORS,
            "body": json.dumps({"error": str(e)}),
        }
'''

# ─────────────────────────────────────────────────────────────
# LAMBDA 2: rakshak-reports-handler
# ─────────────────────────────────────────────────────────────
REPORTS_CODE = '''
import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb", region_name="ap-south-1")
table = dynamodb.Table("rakshak-incidents")

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "")

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        # POST /reports/submit
        if method == "POST" and path.endswith("/reports/submit"):
            body = json.loads(event.get("body", "{}") or "{}")
            item = {
                "incident_id": str(uuid.uuid4()),
                "created_at": datetime.utcnow().isoformat() + "Z",
                "status": "pending",
            }
            item.update(body)
            table.put_item(Item=item)
            return {"statusCode": 201, "headers": CORS, "body": json.dumps(item)}

        # GET /reports
        if method == "GET" and (path.endswith("/reports") or path == "/reports"):
            resp = table.scan()
            items = resp.get("Items", [])
            return {"statusCode": 200, "headers": CORS, "body": json.dumps(items, default=str)}

        # PATCH /reports/approve/{id}
        if method == "PATCH" and "/reports/approve/" in path:
            incident_id = path.split("/reports/approve/")[-1]
            # Need to get the item first to retrieve created_at (SK)
            scan = table.scan(
                FilterExpression=boto3.dynamodb.conditions.Attr("incident_id").eq(incident_id)
            )
            items = scan.get("Items", [])
            if not items:
                return {"statusCode": 404, "headers": CORS, "body": json.dumps({"error": "not found"})}
            created_at = items[0]["created_at"]
            table.update_item(
                Key={"incident_id": incident_id, "created_at": created_at},
                UpdateExpression="SET #s = :s, approved_at = :t",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": "approved", ":t": datetime.utcnow().isoformat() + "Z"},
            )
            return {"statusCode": 200, "headers": CORS, "body": json.dumps({"incident_id": incident_id, "status": "approved"})}

        # PATCH /reports/reject/{id}
        if method == "PATCH" and "/reports/reject/" in path:
            incident_id = path.split("/reports/reject/")[-1]
            scan = table.scan(
                FilterExpression=boto3.dynamodb.conditions.Attr("incident_id").eq(incident_id)
            )
            items = scan.get("Items", [])
            if not items:
                return {"statusCode": 404, "headers": CORS, "body": json.dumps({"error": "not found"})}
            created_at = items[0]["created_at"]
            table.update_item(
                Key={"incident_id": incident_id, "created_at": created_at},
                UpdateExpression="SET #s = :s, rejected_at = :t",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": "rejected", ":t": datetime.utcnow().isoformat() + "Z"},
            )
            return {"statusCode": 200, "headers": CORS, "body": json.dumps({"incident_id": incident_id, "status": "rejected"})}

        return {"statusCode": 404, "headers": CORS, "body": json.dumps({"error": "route not found"})}

    except Exception as e:
        return {"statusCode": 500, "headers": CORS, "body": json.dumps({"error": str(e)})}
'''

# ─────────────────────────────────────────────────────────────
# LAMBDA 3: rakshak-sos-handler
# ─────────────────────────────────────────────────────────────
SOS_CODE = '''
import json
import boto3
from boto3.dynamodb.conditions import Attr
from datetime import datetime

dynamodb = boto3.resource("dynamodb", region_name="ap-south-1")
table = dynamodb.Table("rakshak-sos-alerts")

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "")

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        # GET /sos/live
        if method == "GET" and path.endswith("/sos/live"):
            resp = table.scan(FilterExpression=Attr("status").eq("active"))
            return {"statusCode": 200, "headers": CORS, "body": json.dumps(resp.get("Items", []), default=str)}

        # POST /sos/dispatch/{id}
        if method == "POST" and "/sos/dispatch/" in path:
            sos_id = path.split("/sos/dispatch/")[-1]
            table.update_item(
                Key={"sos_id": sos_id},
                UpdateExpression="SET #s = :s, dispatched_at = :t",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": "dispatched", ":t": datetime.utcnow().isoformat() + "Z"},
            )
            return {"statusCode": 200, "headers": CORS, "body": json.dumps({"sos_id": sos_id, "status": "dispatched"})}

        # PATCH /sos/resolve/{id}
        if method == "PATCH" and "/sos/resolve/" in path:
            sos_id = path.split("/sos/resolve/")[-1]
            table.update_item(
                Key={"sos_id": sos_id},
                UpdateExpression="SET #s = :s, resolved_at = :t",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": "resolved", ":t": datetime.utcnow().isoformat() + "Z"},
            )
            return {"statusCode": 200, "headers": CORS, "body": json.dumps({"sos_id": sos_id, "status": "resolved"})}

        return {"statusCode": 404, "headers": CORS, "body": json.dumps({"error": "route not found"})}

    except Exception as e:
        return {"statusCode": 500, "headers": CORS, "body": json.dumps({"error": str(e)})}
'''

# ─────────────────────────────────────────────────────────────
# LAMBDA 4: rakshak-patrol-handler
# ─────────────────────────────────────────────────────────────
PATROL_CODE = '''
import json
import boto3
from datetime import datetime

dynamodb = boto3.resource("dynamodb", region_name="ap-south-1")
table = dynamodb.Table("rakshak-patrols")

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "")
    path_params = event.get("pathParameters") or {}

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        # GET /patrols
        if method == "GET":
            resp = table.scan()
            return {"statusCode": 200, "headers": CORS, "body": json.dumps(resp.get("Items", []), default=str)}

        # PATCH /patrols/{id}/status
        if method == "PATCH" and "/status" in path:
            patrol_id = path_params.get("id") or path.split("/patrols/")[-1].split("/status")[0]
            body = json.loads(event.get("body", "{}") or "{}")
            new_status = body.get("status", "Unknown")
            table.update_item(
                Key={"patrol_id": patrol_id},
                UpdateExpression="SET #s = :s, updated_at = :t",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": new_status, ":t": datetime.utcnow().isoformat() + "Z"},
            )
            return {"statusCode": 200, "headers": CORS, "body": json.dumps({"patrol_id": patrol_id, "status": new_status})}

        return {"statusCode": 404, "headers": CORS, "body": json.dumps({"error": "route not found"})}

    except Exception as e:
        return {"statusCode": 500, "headers": CORS, "body": json.dumps({"error": str(e)})}
'''


def create_or_update_lambda(name, code, description):
    import io, zipfile
    # Create zip in memory
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('lambda_function.py', code.strip())
    zip_bytes = buf.getvalue()

    try:
        resp = lambda_client.create_function(
            FunctionName=name,
            Runtime='python3.12',
            Role=ROLE_ARN,
            Handler='lambda_function.lambda_handler',
            Code={'ZipFile': zip_bytes},
            Description=description,
            Timeout=30,
            MemorySize=256,
        )
        print(f"✅ Created Lambda: {name} — ARN: {resp['FunctionArn']}")
        return resp['FunctionArn']
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceConflictException':
            # Update existing
            resp = lambda_client.update_function_code(
                FunctionName=name,
                ZipFile=zip_bytes,
            )
            arn = resp['FunctionArn']
            print(f"🔄 Updated Lambda: {name} — ARN: {arn}")
            return arn
        else:
            raise


arns = {}
arns['rakshak-score-refresh']   = create_or_update_lambda('rakshak-score-refresh',   SCORE_REFRESH_CODE, 'Refresh zone risk scores via ML inference')
arns['rakshak-reports-handler'] = create_or_update_lambda('rakshak-reports-handler', REPORTS_CODE,       'CRUD for incident reports')
arns['rakshak-sos-handler']     = create_or_update_lambda('rakshak-sos-handler',     SOS_CODE,           'SOS alert management')
arns['rakshak-patrol-handler']  = create_or_update_lambda('rakshak-patrol-handler',  PATROL_CODE,        'Patrol unit management')

# Save ARNs for next script
import json as _json
with open('/tmp/rakshak_arns.json', 'w') as f:
    _json.dump(arns, f, indent=2)

print("\nAll Lambda ARNs saved to /tmp/rakshak_arns.json")
print(_json.dumps(arns, indent=2))
"""
Fix rakshak-score-refresh Lambda.

Root causes identified:
1. The v2 Lambda called SageMaker directly with a raw feature array.
   SageMaker returns a regression value > 1.0 (e.g. 2.0), not a probability.
   The threshold `safe_score >= 0.6 → LOW` always fires because 2.0 >= 0.6.

2. The correct path is to invoke `rakshak-test-inference` (the /predict Lambda)
   per zone, which handles feature engineering internally and returns:
   { risk_level: "High"|"Medium"|"Low", risk_index: 0-100, confidence: 0-1 }

3. safe_score should be derived as 1 - (risk_index / 100) so that:
   - HIGH risk  → low safe_score  (e.g. risk_index=94 → safe_score=0.06)
   - LOW risk   → high safe_score (e.g. risk_index=20 → safe_score=0.80)

4. The original task2_lambdas.py used thresholds:
   score >= 0.7 → HIGH, >= 0.4 → MEDIUM, else LOW
   But since we now use safe_score = 1 - risk_index/100, we invert:
   safe_score < 0.3  → HIGH  (risk_index > 70)
   safe_score < 0.6  → MEDIUM (risk_index > 40)
   else              → LOW

Zone lat/lon lookup table for the 44 Chennai pincodes used by the dashboard.
"""
import boto3, io, zipfile, json, os
from botocore.exceptions import ClientError

lambda_client = boto3.client('lambda', region_name='ap-south-1')

FIXED_SCORE_REFRESH_CODE = r'''
import json, os, boto3, urllib.request, urllib.error
from datetime import datetime

REGION  = 'ap-south-1'
KEY_ID  = os.environ.get('RAKSHAK_AWS_ACCESS_KEY_ID')
SECRET  = os.environ.get('RAKSHAK_AWS_SECRET_ACCESS_KEY')

# Public HTTP endpoint — no IAM needed
PREDICT_URL = 'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com/predict'

CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
}

# Lat/lon lookup for Chennai pincodes (matches dashboard ZONES array)
PINCODE_COORDS = {
    '600001': (13.0827, 80.2707), '600002': (13.0878, 80.2785),
    '600003': (13.0950, 80.2866), '600004': (13.0732, 80.2609),
    '600005': (13.0569, 80.2787), '600006': (13.0715, 80.2740),
    '600007': (13.1127, 80.2966), '600008': (13.1186, 80.2487),
    '600009': (13.1483, 80.2355), '600010': (13.1675, 80.2617),
    '600011': (13.0827, 80.2487), '600012': (13.0950, 80.2193),
    '600013': (13.0732, 80.2193), '600014': (13.0339, 80.2553),
    '600015': (13.0339, 80.2707), '600017': (13.0067, 80.2570),
    '600018': (13.0521, 80.2193), '600019': (13.0475, 80.2030),
    '600020': (13.0521, 80.2118), '600024': (12.9815, 80.2209),
    '600028': (12.9995, 80.2666), '600029': (12.9845, 80.2657),
    '600032': (13.0350, 80.2323), '600033': (13.0521, 80.2030),
    '600034': (13.0339, 80.2193), '600035': (13.0402, 80.2091),
    '600036': (13.0883, 80.2105), '600040': (13.0850, 80.2101),
    '600042': (13.0883, 80.1762), '600044': (13.0339, 80.1575),
    '600045': (13.0237, 80.1762), '600050': (12.9673, 80.1501),
    '600053': (12.9515, 80.1438), '600056': (12.9625, 80.2387), '600058': (13.1127, 80.2966),
    '600061': (12.9000, 80.2277), '600064': (12.9240, 80.1958),
    '600073': (12.9150, 80.1501), '600078': (13.1144, 80.1606),
    '600081': (13.1675, 80.2617), '600082': (13.1675, 80.2355), '600083': (13.1483, 80.2355),
    '600099': (13.1186, 80.2091), '600118': (12.9065, 80.1958),
    '600058': (13.1167, 80.2922), '600081': (13.1651, 80.3007),
}


def call_predict(pincode, hour, day_of_week):
    """Call /predict via HTTP — no IAM needed, uses the public API Gateway URL."""
    lat, lon = PINCODE_COORDS.get(str(pincode), (13.0827, 80.2707))
    is_night   = 1 if (hour < 6 or hour >= 22) else 0
    is_weekend = 1 if day_of_week in [5, 6] else 0

    payload = json.dumps({
        'lat':       lat,
        'lon':       lon,
        'hour':      hour,
        'dayofweek': day_of_week,
        'isnight':   is_night,
        'isweekend': is_weekend,
    }).encode()

    req = urllib.request.Request(
        PREDICT_URL,
        data=payload,
        headers={'Content-Type': 'application/json'},
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())
    # Returns: { risk_level: "High"|"Medium"|"Low", risk_index: 0-100, confidence: 0-1 }


def lambda_handler(event, context):
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS, 'body': ''}

    try:
        body  = json.loads(event.get('body', '{}') or '{}')
        zones = body.get('zones', [])

        now = datetime.utcnow()
        default_hour = now.hour
        default_dow  = now.weekday()

        results = []
        for zone in zones:
            pincode_str = str(zone.get('pincode', '600001'))
            hour        = int(zone.get('hour', default_hour))
            day_of_week = int(zone.get('day_of_week', default_dow))

            try:
                pred = call_predict(pincode_str, hour, day_of_week)

                # /predict returns risk_level as "High"/"Medium"/"Low"
                raw_level  = str(pred.get('risk_level', 'Low')).upper()
                risk_index = float(pred.get('risk_index', 50))

                # Normalise risk_level
                if 'HIGH' in raw_level:
                    risk_level = 'HIGH'
                elif 'MED' in raw_level:
                    risk_level = 'MEDIUM'
                else:
                    risk_level = 'LOW'

                # safe_score: 1 - normalised risk_index (0-100 → 0.0-1.0)
                # HIGH risk (index=94) → safe_score=0.06
                # LOW risk  (index=20) → safe_score=0.80
                safe_score = round(1.0 - (risk_index / 100.0), 4)
                safe_score = max(0.0, min(1.0, safe_score))

                print(f"[score-refresh] {pincode_str} h={hour} dow={day_of_week} "
                      f"risk_index={risk_index} risk_level={risk_level} safe_score={safe_score}")

            except Exception as e:
                print(f"[score-refresh] ERROR {pincode_str}: {type(e).__name__}: {e}")
                risk_level = 'MEDIUM'
                safe_score = 0.5

            results.append({
                'pincode':    pincode_str,
                'safe_score': safe_score,
                'risk_level': risk_level,
            })

        return {
            'statusCode': 200,
            'headers': CORS,
            'body': json.dumps({'results': results}),
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': CORS,
            'body': json.dumps({'error': str(e)}),
        }
'''


def deploy():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('lambda_function.py', FIXED_SCORE_REFRESH_CODE.strip())
    zip_bytes = buf.getvalue()

    try:
        lambda_client.update_function_code(
            FunctionName='rakshak-score-refresh',
            ZipFile=zip_bytes,
        )
        print('✅ Updated rakshak-score-refresh code')
    except ClientError as e:
        print(f'❌ update_function_code failed: {e}')
        raise

    import time; time.sleep(3)

    try:
        lambda_client.update_function_configuration(
            FunctionName='rakshak-score-refresh',
            Timeout=60,
            MemorySize=256,
        )
        print('✅ Updated configuration (timeout=60s)')
    except ClientError as e:
        print(f'⚠️  update_function_configuration failed: {e}')


def test():
    """Test the live endpoint with 3 pincodes × 2 time slots."""
    import urllib.request

    url = 'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com/score/refresh'
    test_cases = [
        # (label, zones payload)
        ('Late night weekend (expect HIGH)', [
            {'pincode': '600001', 'hour': 23, 'day_of_week': 6},
            {'pincode': '600034', 'hour': 2,  'day_of_week': 6},
            {'pincode': '600017', 'hour': 1,  'day_of_week': 5},
        ]),
        ('Daytime weekday (expect lower risk)', [
            {'pincode': '600001', 'hour': 14, 'day_of_week': 2},
            {'pincode': '600034', 'hour': 10, 'day_of_week': 1},
            {'pincode': '600017', 'hour': 9,  'day_of_week': 3},
        ]),
    ]

    for label, zones in test_cases:
        print(f'\n── {label} ──')
        req = urllib.request.Request(
            url,
            data=json.dumps({'zones': zones}).encode(),
            headers={'Content-Type': 'application/json'},
            method='POST',
        )
        with urllib.request.urlopen(req, timeout=30) as r:
            result = json.loads(r.read())
        # Handle both bare array and {"results": [...]} wrapper
        items = result.get('results', result) if isinstance(result, dict) else result
        for item in items:
            print(f"  {item['pincode']}  safe_score={item['safe_score']}  risk_level={item['risk_level']}")


if __name__ == '__main__':
    import sys
    if '--test-only' in sys.argv:
        print('=== Testing live endpoint (no deploy) ===')
        test()
    else:
        print('=== Deploying fixed rakshak-score-refresh Lambda ===')
        deploy()
        print('\n=== Waiting 5s for Lambda to update ===')
        import time; time.sleep(5)
        print('\n=== Testing live endpoint ===')
        test()
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: { port: 5173 },
})
import fs from 'fs';

const PINCODES = [
  "600001","600002","600003","600004","600005","600006","600007","600008",
  "600009","600010","600011","600012","600013","600014","600015","600017",
  "600018","600019","600020","600024","600028","600029","600032","600033",
  "600034","600035","600036","600040","600042","600044","600045","600050",
  "600053","600056","600058","600061","600064","600073","600078","600081",
  "600082","600083","600099","600118"
];

const PINCODE_NAMES = {
  "600001":"Park Town","600002":"Sowcarpet","600003":"Royapuram",
  "600004":"Chintadripet","600005":"Royapettah","600006":"Triplicane",
  "600007":"Egmore","600008":"Nungambakkam","600009":"Kilpauk",
  "600010":"Aminjikarai","600011":"Kodambakkam","600012":"Ashok Nagar",
  "600013":"Tiruvottiyur","600014":"Perambur","600015":"Pattabiram",
  "600017":"T. Nagar","600018":"Abiramapuram","600019":"Vyasarpadi",
  "600020":"Saidapet","600024":"Pallavaram","600028":"Adyar",
  "600029":"Besant Nagar","600032":"Alwarpet","600033":"Valasaravakkam",
  "600034":"Anna Nagar West","600035":"Anna Nagar East","600036":"Arumbakkam",
  "600040":"Nanganallur","600042":"Velachery","600044":"Perungudi",
  "600045":"Thoraipakkam","600050":"Mogappair","600053":"Villivakkam",
  "600056":"Kolathur","600058":"Royapuram","600061":"Mugalivakkam",
  "600064":"Medavakkam","600073":"Selaiyur","600078":"Ambattur",
  "600081":"Manali","600082":"Puzhal","600083":"Madhavaram",
  "600099":"Kundrathur","600118":"Perumbakkam"
};

async function fetchPincodePolygon(pincode) {
  const query = `
    [out:json];
    relation["boundary"="postal_code"]["postal_code"="${pincode}"]["addr:country"="IN"];
    out geom;
  `;
  const url = 'https://overpass-api.de/api/interpreter';
  const resp = await fetch(url, {
    method: 'POST',
    body: 'data=' + encodeURIComponent(query),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
  });
  const json = await resp.json();
  return json.elements;
}

function buildPolygonFromOSM(element) {
  if (!element.members) return null;
  const outer = element.members.find(m => m.role === 'outer' && m.geometry);
  if (!outer) return null;
  const coords = outer.geometry.map(p => [p.lon, p.lat]);
  if (coords[0] !== coords[coords.length-1]) coords.push(coords[0]);
  return coords;
}

async function main() {
  const features = [];
  const missing = [];

  for (const pincode of PINCODES) {
    console.log(`Fetching ${pincode} - ${PINCODE_NAMES[pincode]}...`);
    try {
      await new Promise(r => setTimeout(r, 1000)); // rate limit
      const elements = await fetchPincodePolygon(pincode);
      if (elements && elements.length > 0) {
        const coords = buildPolygonFromOSM(elements[0]);
        if (coords) {
          features.push({
            type: "Feature",
            properties: {
              pincode,
              name: PINCODE_NAMES[pincode],
              risk_score: 50,
              risk_level: "MEDIUM"
            },
            geometry: { type: "Polygon", coordinates: [coords] }
          });
          console.log(`  ✅ ${pincode} done (${coords.length} points)`);
        } else {
          console.log(`  ⚠️  ${pincode} no outer geometry`);
          missing.push(pincode);
        }
      } else {
        console.log(`  ❌ ${pincode} not found in OSM`);
        missing.push(pincode);
      }
    } catch(e) {
      console.log(`  ❌ ${pincode} error: ${e.message}`);
      missing.push(pincode);
    }
  }

  const geojson = { type: "FeatureCollection", features };
  fs.writeFileSync(
    'public/chennai-zones-osm.geojson',
    JSON.stringify(geojson, null, 2)
  );
  console.log(`\nDone. ${features.length}/${PINCODES.length} zones fetched from OSM.`);
  if (missing.length > 0) {
    console.log(`Missing pincodes: ${missing.join(', ')}`);
  }
  console.log('Saved to public/chennai-zones-osm.geojson');
}

main();
/**
 * Extracts and merges accurate boundaries for 12 hexagonal-approximated Chennai pincodes.
 * Sources: datameet/PincodeBoundary (7), OSM Ward 93 (1), 16-pt circle (4).
 */

const fs = require('fs');
const https = require('https');
const http = require('http');

const MISSING = ["600019","600029","600044","600045","600050","600053","600056","600058","600064","600073","600099","600118"];

const NAMES = {
  "600019":"Vyasarpadi","600029":"Besant Nagar","600044":"Perungudi",
  "600045":"Thoraipakkam","600050":"Mogappair","600053":"Villivakkam",
  "600056":"Kolathur","600058":"Royapuram","600064":"Medavakkam",
  "600073":"Selaiyur","600099":"Kundrathur","600118":"Perumbakkam"
};

// datameet pin → our pin (matched by geographic name)
const DATAMEET_MAP = {
  "600039": "600019",  // VYASARPADI SO → Vyasarpadi
  "600090": "600029",  // BESANT NAGAR  → Besant Nagar
  "600096": "600044",  // PERUNGUDI     → Perungudi
  "600097": "600045",  // OGGIAM THORAIPAKKAM → Thoraipakkam
  "600049": "600053",  // VILLIVAKKAM   → Villivakkam
  "600099": "600056",  // Kolathur      → Kolathur
  "600013": "600058",  // ROYAPURAM SO  → Royapuram
};

function circlePolygon(lat, lon, radiusKm, n = 16) {
  const latR = radiusKm / 111.32;
  const lonR = radiusKm / (111.32 * Math.cos((lat * Math.PI) / 180));
  const coords = [];
  for (let i = 0; i < n; i++) {
    const angle = (2 * Math.PI * i) / n;
    coords.push([
      parseFloat((lon + lonR * Math.cos(angle)).toFixed(6)),
      parseFloat((lat + latR * Math.sin(angle)).toFixed(6)),
    ]);
  }
  coords.push(coords[0]);
  return { type: "Polygon", coordinates: [coords] };
}

// 16-pt circle fallbacks for areas not in datameet or OSM ward data
const CIRCLE_FALLBACKS = {
  "600064": { lat: 12.9230, lon: 80.1883, r: 1.5 },
  "600073": { lat: 12.9187, lon: 80.1311, r: 1.5 },
  "600099": { lat: 12.9958, lon: 80.0973, r: 1.5 },
  "600118": { lat: 12.9050, lon: 80.1969, r: 1.5 },
};

// OSM Ward 93 polygon for Mogappair (fetched once, embedded here to avoid re-fetch)
const MOGAPPAIR_WARD93_URL = "https://overpass-api.de/api/interpreter";
const MOGAPPAIR_QUERY = `[out:json][timeout:30];relation(7888171);out geom;`;

async function fetchOverpass(query) {
  return new Promise((resolve, reject) => {
    const body = "data=" + encodeURIComponent(query);
    const opts = {
      hostname: "overpass-api.de",
      path: "/api/interpreter",
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", "Content-Length": Buffer.byteLength(body) }
    };
    const req = https.request(opts, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function relationToPolygon(rel) {
  const outerWays = rel.members.filter(m => m.type === 'way' && (m.role === 'outer' || m.role === ''));
  const coords = [];
  for (const way of outerWays) {
    const pts = (way.geometry || []).map(g => [g.lon, g.lat]);
    if (coords.length > 0 && pts.length > 0) {
      const last = coords[coords.length - 1];
      if (last[0] === pts[0][0] && last[1] === pts[0][1]) {
        coords.push(...pts.slice(1));
      } else {
        coords.push(...pts);
      }
    } else {
      coords.push(...pts);
    }
  }
  if (coords.length > 0 && (coords[0][0] !== coords[coords.length-1][0] || coords[0][1] !== coords[coords.length-1][1])) {
    coords.push(coords[0]);
  }
  return { type: "Polygon", coordinates: [coords] };
}

async function main() {
  const features = [];

  // ── Step 1: Extract from datameet Chennai boundary file ──
  const dmPath = '/tmp/india_pincodes.geojson';
  if (!fs.existsSync(dmPath)) {
    console.error('❌ Missing /tmp/india_pincodes.geojson — run the download step first');
    process.exit(1);
  }
  const dm = JSON.parse(fs.readFileSync(dmPath));
  for (const feat of dm.features) {
    const dmPin = String(feat.properties.pin || '');
    const ourPin = DATAMEET_MAP[dmPin];
    if (ourPin) {
      features.push({
        type: "Feature",
        geometry: feat.geometry,
        properties: { pincode: ourPin, name: NAMES[ourPin], risk_score: 50, risk_level: "MEDIUM", source: `datameet:${dmPin}` }
      });
      console.log(`✅ ${ourPin} (${NAMES[ourPin]}) — datameet:${dmPin} (${feat.properties.area_name || feat.properties.name})`);
    }
  }

  // ── Step 2: OSM Ward 93 for Mogappair ──
  console.log('\nFetching OSM Ward 93 for Mogappair...');
  try {
    const osm = await fetchOverpass(MOGAPPAIR_QUERY);
    const rel = osm.elements.find(e => e.type === 'relation');
    if (rel) {
      const geo = relationToPolygon(rel);
      features.push({
        type: "Feature",
        geometry: geo,
        properties: { pincode: "600050", name: "Mogappair", risk_score: 50, risk_level: "MEDIUM", source: "osm:ward93" }
      });
      console.log(`✅ 600050 (Mogappair) — OSM Ward 93 (${geo.coordinates[0].length} pts)`);
    } else {
      throw new Error('No relation found');
    }
  } catch (e) {
    console.log(`⚠️  Mogappair OSM fetch failed (${e.message}), using 16-pt circle`);
    const { lat, lon, r } = CIRCLE_FALLBACKS["600050"] || { lat: 13.0835, lon: 80.1840, r: 1.5 };
    features.push({
      type: "Feature",
      geometry: circlePolygon(lat, lon, r),
      properties: { pincode: "600050", name: "Mogappair", risk_score: 50, risk_level: "MEDIUM", source: "approx:circle" }
    });
  }

  // ── Step 3: 16-point circle approximations for remaining 4 ──
  for (const [pin, { lat, lon, r }] of Object.entries(CIRCLE_FALLBACKS)) {
    features.push({
      type: "Feature",
      geometry: circlePolygon(lat, lon, r),
      properties: { pincode: pin, name: NAMES[pin], risk_score: 50, risk_level: "MEDIUM", source: "approx:circle" }
    });
    console.log(`✅ ${pin} (${NAMES[pin]}) — 16-pt circle at ${lat},${lon}`);
  }

  const out = { type: "FeatureCollection", features };
  fs.writeFileSync('rakshak-dashboard/scripts/missing-zones.geojson', JSON.stringify(out, null, 2));
  console.log(`\nExtracted ${features.length}/12 missing zones → missing-zones.geojson`);

  const srcCounts = {};
  for (const f of features) {
    const s = f.properties.source.split(':')[0];
    srcCounts[s] = (srcCounts[s] || 0) + 1;
  }
  console.log('Sources:', srcCounts);
}

main().catch(e => { console.error(e); process.exit(1); });
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PINCODE_NAMES = {
  "600001":"Park Town","600002":"Sowcarpet","600003":"Royapuram",
  "600004":"Chintadripet","600005":"Royapettah","600006":"Triplicane",
  "600007":"Egmore","600008":"Nungambakkam","600009":"Kilpauk",
  "600010":"Aminjikarai","600011":"Kodambakkam","600012":"Ashok Nagar",
  "600013":"Tiruvottiyur","600014":"Perambur","600015":"Pattabiram",
  "600017":"T. Nagar","600018":"Abiramapuram","600019":"Vyasarpadi",
  "600020":"Saidapet","600024":"Pallavaram","600028":"Adyar",
  "600029":"Besant Nagar","600032":"Alwarpet","600033":"Valasaravakkam",
  "600034":"Anna Nagar West","600035":"Anna Nagar East","600036":"Arumbakkam",
  "600040":"Nanganallur","600042":"Velachery","600044":"Perungudi",
  "600045":"Thoraipakkam","600050":"Mogappair","600053":"Villivakkam",
  "600056":"Kolathur","600058":"Royapuram","600061":"Mugalivakkam",
  "600064":"Medavakkam","600073":"Selaiyur","600078":"Ambattur",
  "600081":"Manali","600082":"Puzhal","600083":"Madhavaram",
  "600099":"Kundrathur","600118":"Perumbakkam"
};

const RISK = {
  "600001":"HIGH","600006":"HIGH","600007":"HIGH","600058":"HIGH","600081":"HIGH",
  "600002":"MEDIUM","600003":"MEDIUM","600004":"MEDIUM","600005":"MEDIUM",
  "600008":"MEDIUM","600009":"MEDIUM","600010":"MEDIUM","600011":"MEDIUM",
  "600012":"MEDIUM","600013":"MEDIUM",
};

// Accurate centroids (lat, lon) for the 12 pincodes NOT in the KML
const MISSING_CENTROIDS = {
  "600019": [13.1021, 80.2498],  // Vyasarpadi
  "600029": [12.9992, 80.2703],  // Besant Nagar
  "600044": [12.9568, 80.2440],  // Perungudi
  "600045": [12.9437, 80.2356],  // Thoraipakkam
  "600050": [13.0837, 80.1743],  // Mogappair
  "600053": [13.1176, 80.2175],  // Villivakkam
  "600056": [13.1118, 80.2296],  // Kolathur
  "600058": [13.1127, 80.2966],  // Royapuram (Harbour)
  "600064": [12.9307, 80.1978],  // Medavakkam
  "600073": [12.9057, 80.1612],  // Selaiyur
  "600099": [13.0308, 80.1050],  // Kundrathur
  "600118": [12.9029, 80.2148],  // Perumbakkam
};
const APPROX_RADIUS_DEG = 0.022; // ~2.4 km

function hexPolygon(lat, lon, r) {
  const pts = [];
  for (let i = 0; i <= 6; i++) {
    const angle = (Math.PI / 3) * i;
    pts.push([lon + r * Math.cos(angle), lat + r * 0.85 * Math.sin(angle)]);
  }
  return pts;
}

// --- Parse KML ---
const kmlPath = path.join(__dirname, '../public/Final_Chennai_Pincode.kml');
const kml = fs.readFileSync(kmlPath, 'utf8');

const TARGET = new Set(Object.keys(PINCODE_NAMES));
const features = [];
const found = new Set();

const pmRe = /<Placemark[\s\S]*?<\/Placemark>/g;
let pm;
while ((pm = pmRe.exec(kml)) !== null) {
  const block = pm[0];
  const pcM = block.match(/<SimpleData name="Pincode">(.*?)<\/SimpleData>/);
  if (!pcM) continue;
  const pincode = pcM[1].trim();
  if (!TARGET.has(pincode) || found.has(pincode)) continue;

  const coordsM = block.match(/<outerBoundaryIs>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>/);
  if (!coordsM) continue;

  const coords = coordsM[1].trim().split(/\s+/)
    .filter(c => c.includes(','))
    .map(c => {
      const [lng, lat] = c.split(',').map(Number);
      return [lng, lat];
    })
    .filter(p => !isNaN(p[0]) && !isNaN(p[1]));

  if (coords.length < 3) continue;
  if (coords[0][0] !== coords[coords.length - 1][0] || coords[0][1] !== coords[coords.length - 1][1]) {
    coords.push(coords[0]);
  }

  found.add(pincode);
  features.push({
    type: "Feature",
    properties: {
      pincode,
      name: PINCODE_NAMES[pincode] || pincode,
      risk_level: RISK[pincode] || "LOW",
      source: "india_post_kml"
    },
    geometry: { type: "Polygon", coordinates: [coords] }
  });
}

console.log(`KML: extracted ${found.size} of ${TARGET.size} pincodes`);

// --- Add missing pincodes as hex approximations ---
let approxCount = 0;
for (const pincode of TARGET) {
  if (found.has(pincode)) continue;
  const centroid = MISSING_CENTROIDS[pincode];
  if (!centroid) { console.log(`  ⚠️  No centroid for ${pincode}`); continue; }
  const [lat, lon] = centroid;
  const coords = hexPolygon(lat, lon, APPROX_RADIUS_DEG);
  features.push({
    type: "Feature",
    properties: {
      pincode,
      name: PINCODE_NAMES[pincode],
      risk_level: RISK[pincode] || "LOW",
      source: "approximate"
    },
    geometry: { type: "Polygon", coordinates: [coords] }
  });
  approxCount++;
  console.log(`  ≈ ${pincode} ${PINCODE_NAMES[pincode]} (hex approximation)`);
}

// Sort by pincode
features.sort((a, b) => a.properties.pincode.localeCompare(b.properties.pincode));

const geojson = { type: "FeatureCollection", features };
const outPath = path.join(__dirname, '../public/chennai-zones-osm.geojson');
fs.writeFileSync(outPath, JSON.stringify(geojson, null, 2));

console.log(`\nTotal: ${features.length} zones`);
console.log(`  - ${found.size} from India Post KML (no coordinate offset)`);
console.log(`  - ${approxCount} hexagonal approximations`);
console.log(`Saved to public/chennai-zones-osm.geojson`);
const fs = require('fs');

const REPLACING = [
  "600019","600029","600044","600045","600050","600053",
  "600056","600058","600064","600073","600099","600118"
];

const main_path = 'rakshak-dashboard/public/chennai-zones-osm.geojson';
const missing_path = 'rakshak-dashboard/scripts/missing-zones.geojson';

const main = JSON.parse(fs.readFileSync(main_path));
const missing = JSON.parse(fs.readFileSync(missing_path));

const kept = main.features.filter(f => !REPLACING.includes(String(f.properties.pincode)));
const merged = { type: "FeatureCollection", features: [...kept, ...missing.features] };

fs.writeFileSync(main_path, JSON.stringify(merged, null, 2));

console.log(`Total zones: ${merged.features.length}/44`);
console.log('Replaced hexagonal approximations with real/improved boundaries');

// Report sources
const sources = {};
for (const f of missing.features) {
  const src = (f.properties.source || 'unknown').split(':')[0];
  sources[src] = (sources[src] || 0) + 1;
}
console.log('Boundary sources:', sources);

// Check for any remaining hexagons (7-point polygons)
const hexagons = merged.features.filter(f => {
  const geo = f.geometry;
  if (geo.type === 'Polygon') return geo.coordinates[0].length === 7;
  return false;
});
if (hexagons.length === 0) {
  console.log('✅ No hexagonal approximations remaining');
} else {
  console.log('⚠️  Still hexagonal:', hexagons.map(f => f.properties.pincode).join(', '));
}
export const API_BASE = 'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com'

export const ENDPOINTS = {
  // Risk scoring
  scoreRefresh:   `${API_BASE}/score/refresh`,

  // SOS — user app creates, police app reads & acts
  sosLive:        `${API_BASE}/sos/live`,
  sosActive:      `${API_BASE}/police/sos/active`,
  sosDispatch:    (id) => `${API_BASE}/sos/dispatch/${id}`,
  sosResolve:     (id) => `${API_BASE}/sos/resolve/${id}`,

  // Police app
  policeRoute:    `${API_BASE}/police/route`,
  citizensActive: `${API_BASE}/police/citizens/active`,

  // Patrols
  patrolsList:    `${API_BASE}/patrols`,
  patrolStatus:   (id) => `${API_BASE}/patrols/${id}/status`,
  patrolOptimize: `${API_BASE}/patrol/optimize`,

  // Reports
  reportsSubmit:  `${API_BASE}/reports/submit`,
  reportsGet:     `${API_BASE}/reports`,
  reportsApprove: (id) => `${API_BASE}/reports/approve/${id}`,
  reportsReject:  (id) => `${API_BASE}/reports/reject/${id}`,
}

export default ENDPOINTS
export const ZONES = [
  // HIGH
  { c: '600001', n: 'Park Town',    lat: 13.0908, lon: 80.2866, r: 'HIGH' },
  { c: '600006', n: 'Triplicane',   lat: 13.0900, lon: 80.2757, r: 'HIGH' },
  { c: '600007', n: 'Egmore',       lat: 13.1186, lon: 80.2487, r: 'HIGH' },
  { c: '600058', n: 'Royapuram',    lat: 13.1127, lon: 80.2966, r: 'HIGH' },
  { c: '600081', n: 'Manali',       lat: 13.1675, lon: 80.2617, r: 'HIGH' },
  // MEDIUM
  { c: '600002', n: 'Sowcarpet',    lat: 13.0827, lon: 80.2707, r: 'MEDIUM' },
  { c: '600003', n: 'Royapuram',    lat: 13.0569, lon: 80.2787, r: 'MEDIUM' },
  { c: '600004', n: 'Chintadripet', lat: 13.0715, lon: 80.2740, r: 'MEDIUM' },
  { c: '600005', n: 'Royapettah',   lat: 13.1013, lon: 80.2615, r: 'MEDIUM' },
  { c: '600008', n: 'Nungambakkam', lat: 13.1075, lon: 80.2902, r: 'MEDIUM' },
  { c: '600009', n: 'Kilpauk',      lat: 13.0750, lon: 80.2193, r: 'MEDIUM' },
  { c: '600010', n: 'Aminjikarai',  lat: 13.0827, lon: 80.2354, r: 'MEDIUM' },
  { c: '600011', n: 'Perambur',     lat: 13.0732, lon: 80.2609, r: 'MEDIUM' },
  { c: '600012', n: 'Ashok Nagar',  lat: 13.0750, lon: 80.2354, r: 'MEDIUM' },
  { c: '600013', n: 'Tiruvottiyur', lat: 13.0569, lon: 80.2425, r: 'MEDIUM' },
  // LOW
  { c: '600014', n: 'Perambur',        lat: 13.0339, lon: 80.2553, r: 'LOW' },
  { c: '600015', n: 'Pattabiram',      lat: 13.0339, lon: 80.2707, r: 'LOW' },
  { c: '600017', n: 'T. Nagar',        lat: 13.0067, lon: 80.2570, r: 'LOW' },
  { c: '600018', n: 'Abiramapuram',    lat: 13.0521, lon: 80.2193, r: 'LOW' },
  { c: '600019', n: 'Vyasarpadi',      lat: 13.0475, lon: 80.2030, r: 'LOW' },
  { c: '600020', n: 'Saidapet',        lat: 13.0521, lon: 80.2118, r: 'LOW' },
  { c: '600024', n: 'Pallavaram',      lat: 12.9815, lon: 80.2209, r: 'LOW' },
  { c: '600028', n: 'Adyar',           lat: 12.9995, lon: 80.2666, r: 'LOW' },
  { c: '600029', n: 'Besant Nagar',    lat: 12.9845, lon: 80.2657, r: 'LOW' },
  { c: '600032', n: 'Alwarpet',        lat: 13.0350, lon: 80.2323, r: 'LOW' },
  { c: '600033', n: 'Valasaravakkam', lat: 13.0521, lon: 80.2030, r: 'LOW' },
  { c: '600034', n: 'Anna Nagar West', lat: 13.0339, lon: 80.2193, r: 'LOW' },
  { c: '600035', n: 'Anna Nagar East', lat: 13.0402, lon: 80.2091, r: 'LOW' },
  { c: '600036', n: 'Arumbakkam',      lat: 13.0883, lon: 80.2105, r: 'LOW' },
  { c: '600040', n: 'Nanganallur',     lat: 13.0850, lon: 80.2101, r: 'LOW' },
  { c: '600042', n: 'Velachery',       lat: 13.0883, lon: 80.1762, r: 'LOW' },
  { c: '600044', n: 'Perungudi',       lat: 13.0339, lon: 80.1575, r: 'LOW' },
  { c: '600045', n: 'Thoraipakkam',    lat: 13.0237, lon: 80.1762, r: 'LOW' },
  { c: '600050', n: 'Mogappair',       lat: 12.9673, lon: 80.1501, r: 'LOW' },
  { c: '600053', n: 'Villivakkam',     lat: 12.9515, lon: 80.1438, r: 'LOW' },
  { c: '600056', n: 'Kolathur',        lat: 12.9625, lon: 80.2387, r: 'LOW' },
  { c: '600061', n: 'Mugalivakkam',    lat: 12.9000, lon: 80.2277, r: 'LOW' },
  { c: '600064', n: 'Medavakkam',      lat: 12.9240, lon: 80.1958, r: 'LOW' },
  { c: '600073', n: 'Selaiyur',        lat: 12.9150, lon: 80.1501, r: 'LOW' },
  { c: '600078', n: 'Ambattur',        lat: 13.1144, lon: 80.1606, r: 'LOW' },
  { c: '600082', n: 'Puzhal',          lat: 13.1675, lon: 80.2355, r: 'LOW' },
  { c: '600083', n: 'Madhavaram',      lat: 13.1483, lon: 80.2355, r: 'LOW' },
  { c: '600099', n: 'Kundrathur',      lat: 13.1186, lon: 80.2091, r: 'LOW' },
  { c: '600118', n: 'Perumbakkam',     lat: 12.9065, lon: 80.1958, r: 'LOW' },
]

export const PATROL_UNITS = [
  { id:'P-01', vehicle:'TN-01-PA-1234', officers:['SI Priya Kumari','Const. Rajan M'],    zone:'Parrys',         status:'patrolling', contact:'+91-44-2345-6701' },
  { id:'P-02', vehicle:'TN-01-PA-1235', officers:['SI Meena Devi','Const. Selvam K'],     zone:'Royapuram',      status:'patrolling', contact:'+91-44-2345-6702' },
  { id:'P-03', vehicle:'TN-01-PA-1236', officers:['SI Kavitha R','Const. Murugan S'],     zone:'Perambur',       status:'patrolling', contact:'+91-44-2345-6703' },
  { id:'P-04', vehicle:'TN-01-PA-1237', officers:['SI Lakshmi V','Const. Senthil P'],     zone:'Vepery',         status:'patrolling', contact:'+91-44-2345-6704' },
  { id:'P-05', vehicle:'TN-01-PA-1238', officers:['SI Divya S','Const. Arjun T'],         zone:'Egmore',         status:'patrolling', contact:'+91-44-2345-6705' },
  { id:'P-06', vehicle:'TN-01-PA-1239', officers:['SI Sangeetha N','Const. Karthi R'],    zone:'Kilpauk',        status:'patrolling', contact:'+91-44-2345-6706' },
  { id:'P-07', vehicle:'TN-01-PA-1240', officers:['SI Anitha B','Const. Vijay M'],        zone:'T Nagar',        status:'patrolling', contact:'+91-44-2345-6707' },
  { id:'P-08', vehicle:'TN-01-PA-1241', officers:['SI Rekha C','Const. Suresh G'],        zone:'Anna Nagar',     status:'patrolling', contact:'+91-44-2345-6708' },
  { id:'P-09', vehicle:'TN-01-PA-1242', officers:['SI Malathi D','Const. Prakash N'],     zone:'Adyar',          status:'patrolling', contact:'+91-44-2345-6709' },
  { id:'P-10', vehicle:'TN-01-PA-1243', officers:['SI Padma L','Const. Ramesh V'],        zone:'Velachery',      status:'patrolling', contact:'+91-44-2345-6710' },
  { id:'P-11', vehicle:'TN-01-PA-1244', officers:['SI Geetha M','Const. Kumar A'],        zone:'Porur',          status:'patrolling', contact:'+91-44-2345-6711' },
  { id:'P-12', vehicle:'TN-01-PA-1245', officers:['SI Nithya P','Const. Balu S'],         zone:'Ambattur',       status:'patrolling', contact:'+91-44-2345-6712' },
  { id:'P-13', vehicle:'TN-01-PA-1246', officers:['SI Vimala R','Const. Dinesh K'],       zone:'Sholinganallur', status:'patrolling', contact:'+91-44-2345-6713' },
  { id:'P-14', vehicle:'TN-01-PA-1247', officers:['SI Hema S','Const. Mohan T'],          zone:'Medavakkam',     status:'patrolling', contact:'+91-44-2345-6714' },
  { id:'P-15', vehicle:'TN-01-PA-1248', officers:['SI Saranya B','Const. Ganesh V'],      zone:'Kolathur',       status:'patrolling', contact:'+91-44-2345-6715' },
]

export const riskColor = (r) =>
  r === 'HIGH' ? '#FF3B5C' : r === 'MEDIUM' ? '#F59E0B' : '#22C55E'
/**
 * Haversine distance between two {lat, lng} points in meters.
 */
export function haversineDistance(a, b) {
  const R = 6371000
  const dLat = (b.lat - a.lat) * Math.PI / 180
  const dLng = (b.lng - a.lng) * Math.PI / 180
  const x =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(a.lat * Math.PI / 180) * Math.cos(b.lat * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2)
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x))
}

/**
 * Find the nearest patrol unit (status === 'Patrolling') to a given SOS location.
 * Falls back to any patrol if none are patrolling.
 */
export function findNearestPatrol(patrols, sosLocation) {
  const candidates = patrols.filter(p => p.status === 'Patrolling')
  const pool = candidates.length > 0 ? candidates : patrols
  return pool.reduce((nearest, patrol) => {
    const dist = haversineDistance(patrol.position, sosLocation)
    return dist < nearest.dist ? { patrol, dist } : nearest
  }, { patrol: null, dist: Infinity }).patrol
}

/**
 * 20 patrol units with circular waypoint routes around Chennai zones.
 */
export const PATROL_ROUTES = [
  {
    id: 'P1', name: 'Unit Alpha', vehicle: 'PCR-01',
    waypoints: [
      { lat: 13.0827, lng: 80.2707 }, { lat: 13.0850, lng: 80.2750 },
      { lat: 13.0900, lng: 80.2780 }, { lat: 13.0870, lng: 80.2720 },
      { lat: 13.0827, lng: 80.2707 },
    ],
  },
  {
    id: 'P2', name: 'Unit Bravo', vehicle: 'PCR-02',
    waypoints: [
      { lat: 13.0600, lng: 80.2500 }, { lat: 13.0650, lng: 80.2550 },
      { lat: 13.0700, lng: 80.2520 }, { lat: 13.0640, lng: 80.2470 },
      { lat: 13.0600, lng: 80.2500 },
    ],
  },
  {
    id: 'P3', name: 'Unit Charlie', vehicle: 'PCR-03',
    waypoints: [
      { lat: 13.1000, lng: 80.2900 }, { lat: 13.1050, lng: 80.2950 },
      { lat: 13.1100, lng: 80.2920 }, { lat: 13.1040, lng: 80.2870 },
      { lat: 13.1000, lng: 80.2900 },
    ],
  },
  {
    id: 'P4', name: 'Unit Delta', vehicle: 'PCR-04',
    waypoints: [
      { lat: 13.0400, lng: 80.2300 }, { lat: 13.0450, lng: 80.2350 },
      { lat: 13.0500, lng: 80.2320 }, { lat: 13.0440, lng: 80.2270 },
      { lat: 13.0400, lng: 80.2300 },
    ],
  },
  {
    id: 'P5', name: 'Unit Echo', vehicle: 'PCR-05',
    waypoints: [
      { lat: 13.0750, lng: 80.2600 }, { lat: 13.0800, lng: 80.2650 },
      { lat: 13.0820, lng: 80.2610 }, { lat: 13.0770, lng: 80.2570 },
      { lat: 13.0750, lng: 80.2600 },
    ],
  },
  {
    id: 'P6', name: 'Unit Foxtrot', vehicle: 'PCR-06',
    waypoints: [
      { lat: 13.1200, lng: 80.2800 }, { lat: 13.1250, lng: 80.2850 },
      { lat: 13.1280, lng: 80.2820 }, { lat: 13.1220, lng: 80.2770 },
      { lat: 13.1200, lng: 80.2800 },
    ],
  },
  {
    id: 'P7', name: 'Unit Golf', vehicle: 'PCR-07',
    waypoints: [
      { lat: 13.0300, lng: 80.2100 }, { lat: 13.0350, lng: 80.2150 },
      { lat: 13.0380, lng: 80.2120 }, { lat: 13.0320, lng: 80.2070 },
      { lat: 13.0300, lng: 80.2100 },
    ],
  },
  {
    id: 'P8', name: 'Unit Hotel', vehicle: 'PCR-08',
    waypoints: [
      { lat: 13.0950, lng: 80.2400 }, { lat: 13.1000, lng: 80.2450 },
      { lat: 13.1020, lng: 80.2420 }, { lat: 13.0960, lng: 80.2370 },
      { lat: 13.0950, lng: 80.2400 },
    ],
  },
  {
    id: 'P9', name: 'Unit India', vehicle: 'PCR-09',
    waypoints: [
      { lat: 13.0500, lng: 80.2700 }, { lat: 13.0550, lng: 80.2750 },
      { lat: 13.0580, lng: 80.2720 }, { lat: 13.0520, lng: 80.2670 },
      { lat: 13.0500, lng: 80.2700 },
    ],
  },
  {
    id: 'P10', name: 'Unit Juliet', vehicle: 'PCR-10',
    waypoints: [
      { lat: 13.0700, lng: 80.2200 }, { lat: 13.0750, lng: 80.2250 },
      { lat: 13.0780, lng: 80.2220 }, { lat: 13.0720, lng: 80.2170 },
      { lat: 13.0700, lng: 80.2200 },
    ],
  },
  // ── P11–P20: south and west Chennai zones ─────────────────────────────────
  {
    id: 'P11', name: 'Unit Kilo', vehicle: 'PCR-11',
    waypoints: [
      { lat: 13.0100, lng: 80.2100 }, { lat: 13.0150, lng: 80.2150 },
      { lat: 13.0180, lng: 80.2120 }, { lat: 13.0120, lng: 80.2070 },
      { lat: 13.0100, lng: 80.2100 },
    ],
  },
  {
    id: 'P12', name: 'Unit Lima', vehicle: 'PCR-12',
    waypoints: [
      { lat: 13.0200, lng: 80.2400 }, { lat: 13.0250, lng: 80.2450 },
      { lat: 13.0280, lng: 80.2420 }, { lat: 13.0220, lng: 80.2370 },
      { lat: 13.0200, lng: 80.2400 },
    ],
  },
  {
    id: 'P13', name: 'Unit Mike', vehicle: 'PCR-13',
    waypoints: [
      { lat: 13.0900, lng: 80.2100 }, { lat: 13.0950, lng: 80.2150 },
      { lat: 13.0980, lng: 80.2120 }, { lat: 13.0920, lng: 80.2070 },
      { lat: 13.0900, lng: 80.2100 },
    ],
  },
  {
    id: 'P14', name: 'Unit November', vehicle: 'PCR-14',
    waypoints: [
      { lat: 13.1100, lng: 80.2100 }, { lat: 13.1150, lng: 80.2150 },
      { lat: 13.1180, lng: 80.2120 }, { lat: 13.1120, lng: 80.2070 },
      { lat: 13.1100, lng: 80.2100 },
    ],
  },
  {
    id: 'P15', name: 'Unit Oscar', vehicle: 'PCR-15',
    waypoints: [
      { lat: 13.0650, lng: 80.2800 }, { lat: 13.0700, lng: 80.2850 },
      { lat: 13.0730, lng: 80.2820 }, { lat: 13.0670, lng: 80.2770 },
      { lat: 13.0650, lng: 80.2800 },
    ],
  },
  {
    id: 'P16', name: 'Unit Papa', vehicle: 'PCR-16',
    waypoints: [
      { lat: 13.0350, lng: 80.2600 }, { lat: 13.0400, lng: 80.2650 },
      { lat: 13.0430, lng: 80.2620 }, { lat: 13.0370, lng: 80.2570 },
      { lat: 13.0350, lng: 80.2600 },
    ],
  },
  {
    id: 'P17', name: 'Unit Quebec', vehicle: 'PCR-17',
    waypoints: [
      { lat: 13.1300, lng: 80.2600 }, { lat: 13.1350, lng: 80.2650 },
      { lat: 13.1380, lng: 80.2620 }, { lat: 13.1320, lng: 80.2570 },
      { lat: 13.1300, lng: 80.2600 },
    ],
  },
  {
    id: 'P18', name: 'Unit Romeo', vehicle: 'PCR-18',
    waypoints: [
      { lat: 12.9900, lng: 80.2200 }, { lat: 12.9950, lng: 80.2250 },
      { lat: 12.9980, lng: 80.2220 }, { lat: 12.9920, lng: 80.2170 },
      { lat: 12.9900, lng: 80.2200 },
    ],
  },
  {
    id: 'P19', name: 'Unit Sierra', vehicle: 'PCR-19',
    waypoints: [
      { lat: 13.0800, lng: 80.2100 }, { lat: 13.0850, lng: 80.2150 },
      { lat: 13.0880, lng: 80.2120 }, { lat: 13.0820, lng: 80.2070 },
      { lat: 13.0800, lng: 80.2100 },
    ],
  },
  {
    id: 'P20', name: 'Unit Tango', vehicle: 'PCR-20',
    waypoints: [
      { lat: 13.0450, lng: 80.2900 }, { lat: 13.0500, lng: 80.2950 },
      { lat: 13.0530, lng: 80.2920 }, { lat: 13.0470, lng: 80.2870 },
      { lat: 13.0450, lng: 80.2900 },
    ],
  },
]
/**
 * Fetches a road-accurate route from the free public OSRM demo server.
 * No API key or signup required.
 *
 * Coordinates are passed as longitude,latitude (OSRM requirement).
 *
 * @param {Array<{lat: number, lng: number}>} waypoints
 * @returns {Promise<Array<{lat: number, lng: number}>>}
 *   Densely-sampled road coordinates, or the original waypoints on failure.
 */
export async function fetchRoadRoute(waypoints) {
  try {
    // OSRM requires coordinates in lng,lat order
    const coords = waypoints.map(w => `${w.lng},${w.lat}`).join(';')
    const url = `http://router.project-osrm.org/route/v1/driving/${coords}?overview=full&geometries=geojson`

    const res = await fetch(url, { signal: AbortSignal.timeout(12000) })
    if (!res.ok) throw new Error(`OSRM HTTP ${res.status}`)

    const data = await res.json()
    if (!data.routes || data.routes.length === 0) throw new Error('No route found')

    const roadCoords = data.routes[0].geometry.coordinates
    // Treat fewer than 3 points as a failed/degenerate route
    if (roadCoords.length < 3) throw new Error(`Too few road points (${roadCoords.length})`)

    console.log(`Route loaded for patrol: ${roadCoords.length} road points`)
    // OSRM GeoJSON returns [lng, lat] — convert to {lat, lng}
    return roadCoords.map(([lng, lat]) => ({ lat, lng }))
  } catch (e) {
    console.warn(`Road routing failed for waypoints, using direct path: ${e.message}`)
    return waypoints
  }
}
import { useState, useEffect, useCallback, useRef } from 'react'
import { ENDPOINTS } from '../config/api'
import { ZONES } from '../constants/zones'

/**
 * Fetches risk predictions for all zones from the score/refresh endpoint.
 * Returns { data: Map<code, apiResult>, loading, error, refetch }
 */
export function useRiskData() {
  const [data, setData]       = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState(null)
  const intervalRef           = useRef(null)

  const buildMockMap = useCallback(() => {
    const map = new Map()
    ZONES.forEach(z => {
      map.set(z.c, {
        riskLevel:  z.r,
        riskIndex:  z.r === 'HIGH' ? 0.82 : z.r === 'MEDIUM' ? 0.51 : 0.17,
        confidence: 0.74,
      })
    })
    return map
  }, [])

  const fetchAll = useCallback(async () => {
    const now  = new Date()
    const hour = now.getHours()
    const dow  = now.getDay()

    // Build zone payload for the score/refresh endpoint
    const zones = ZONES.map(z => ({
      pincode:   z.c,
      latitude:  z.lat,
      longitude: z.lon,
      time:      now.toISOString(),
      hour,
      day_of_week: dow,
      is_weekend:  (dow === 0 || dow === 6) ? 1 : 0,
      is_night:    (hour < 6 || hour >= 22) ? 1 : 0,
      is_evening:  (hour >= 17 && hour <= 21) ? 1 : 0,
      is_rush_hour: [8, 9, 17, 18, 19].includes(hour) ? 1 : 0,
    }))

    try {
      const res = await fetch(ENDPOINTS.scoreRefresh, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ zones }),
        signal:  AbortSignal.timeout(8000),
      })

      if (!res.ok) throw new Error(`HTTP ${res.status}`)

      const results = await res.json()

      // results is an array of { pincode, safe_score, risk_level }
      const map = new Map()

      // Seed with mock data first so every zone has a fallback
      ZONES.forEach(z => {
        map.set(z.c, {
          riskLevel:  z.r,
          riskIndex:  z.r === 'HIGH' ? 0.82 : z.r === 'MEDIUM' ? 0.51 : 0.17,
          confidence: 0.74,
        })
      })

      // Overlay with live API results
      if (Array.isArray(results)) {
        results.forEach(r => {
          const code = String(r.pincode)
          map.set(code, {
            riskLevel:  r.risk_level  ?? 'LOW',
            riskIndex:  r.safe_score  != null ? r.safe_score : 0.17,
            confidence: 0.90,
          })
        })
      }

      setData(map)
      setError(null)
    } catch (err) {
      console.warn('API unavailable, using mock data')
      if (!data) setData(buildMockMap())
      setError(null)
    } finally {
      setLoading(false)
    }
  }, [buildMockMap]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    fetchAll()
    intervalRef.current = setInterval(fetchAll, 60_000)
    return () => clearInterval(intervalRef.current)
  }, [fetchAll])

  return { data, loading, error, refetch: fetchAll }
}
import { useState, useEffect, useRef, useCallback } from 'react'
import { PATROL_ROUTES, findNearestPatrol, haversineDistance } from '../utils/patrolSimulation'
import { fetchRoadRoute } from '../utils/fetchRoadRoute'
import { ENDPOINTS } from '../config/api'

const TICK_MS       = 100       // 100ms → smooth continuous motion
const STEP          = 0.000025  // degrees per tick — slowed down for realism
const AT_SCENE_MS   = 15000     // 15 seconds at scene before resuming
const ARRIVE_METERS = 300       // within 300m of SOS → AtScene

/**
 * Initialise patrol state from PATROL_ROUTES.
 * Each entry: { id, name, vehicle, position:{lat,lng}, waypointIndex, status, respondingTo, atSceneStart }
 */
function initPatrols() {
  return PATROL_ROUTES.map(route => ({
    id:            route.id,
    name:          route.name,
    vehicle:       route.vehicle,
    position:      { ...route.waypoints[0] },
    waypointIndex: 0,
    status:        'Patrolling',  // 'Patrolling' | 'Responding' | 'AtScene'
    respondingTo:  null,          // { lat, lng } of SOS
    atSceneStart:  null,          // timestamp when AtScene began
  }))
}

export function usePatrolSimulation() {
  const [patrolStates, setPatrolStates] = useState(initPatrols)
  const [routesReady, setRoutesReady]   = useState(false)

  // Ref so dispatchPatrol always reads latest state without stale closure
  const patrolRef      = useRef(patrolStates)
  // Stores road-expanded waypoints per patrol id once OSRM resolves
  const expandedRoutes = useRef({})

  useEffect(() => { patrolRef.current = patrolStates }, [patrolStates])

  // ── Load road-accurate routes once on mount — sequential to avoid rate limiting
  useEffect(() => {
    async function loadRoutes() {
      for (const patrol of PATROL_ROUTES) {
        const roadWaypoints = await fetchRoadRoute(patrol.waypoints)
        expandedRoutes.current[patrol.id] = roadWaypoints
        await new Promise(resolve => setTimeout(resolve, 300))
      }
      setRoutesReady(true)
    }
    loadRoutes()
  }, [])

  // ── Simulation tick — 100ms smooth interpolation ──────────────────────────
  useEffect(() => {
    const id = setInterval(() => {
      // Wait until road routes are loaded before moving
      if (!routesReady) return

      const now = Date.now()
      setPatrolStates(prev =>
        prev.map(patrol => {
          const expandedWaypoints = expandedRoutes.current[patrol.id]
          if (!expandedWaypoints || expandedWaypoints.length === 0) return patrol

          // ── AtScene: hold for AT_SCENE_MS then resume patrolling ────────
          if (patrol.status === 'AtScene') {
            if (now - patrol.atSceneStart >= AT_SCENE_MS) {
              return {
                ...patrol,
                status:       'Patrolling',
                respondingTo: null,
                atSceneStart: null,
              }
            }
            return patrol  // stay put
          }

          // ── Responding: step toward SOS target ─────────────────────────
          if (patrol.status === 'Responding' && patrol.respondingTo) {
            const target = patrol.respondingTo
            const cur    = patrol.position
            const dist   = haversineDistance(cur, target)

            if (dist <= ARRIVE_METERS) {
              return {
                ...patrol,
                position:     { ...target },
                status:       'AtScene',
                atSceneStart: now,
              }
            }

            const dx  = target.lng - cur.lng
            const dy  = target.lat - cur.lat
            const mag = Math.sqrt(dx * dx + dy * dy)
            return {
              ...patrol,
              position: {
                lat: cur.lat + (dy / mag) * STEP,
                lng: cur.lng + (dx / mag) * STEP,
              },
            }
          }

          // ── Patrolling: interpolate along road-expanded waypoints ───────
          const routeLen = expandedWaypoints.length
          const target   = expandedWaypoints[(patrol.waypointIndex + 1) % routeLen]
          const cur      = patrol.position
          const dx       = target.lng - cur.lng
          const dy       = target.lat - cur.lat
          const dist     = Math.sqrt(dx * dx + dy * dy)

          if (dist < STEP) {
            // Reached this waypoint — snap and advance index
            const nextIdx = (patrol.waypointIndex + 1) % routeLen
            return {
              ...patrol,
              position:      { ...expandedWaypoints[nextIdx] },
              waypointIndex: nextIdx,
            }
          }

          // Move STEP degrees toward next road waypoint
          return {
            ...patrol,
            position: {
              lat: cur.lat + (dy / dist) * STEP,
              lng: cur.lng + (dx / dist) * STEP,
            },
          }
        })
      )
    }, TICK_MS)

    return () => clearInterval(id)
  }, [routesReady])

  // ── Sync backend /patrols statuses every 30s ─────────────────────────────
  useEffect(() => {
    const syncStatuses = async () => {
      try {
        const res = await fetch(ENDPOINTS.patrolsList, {
          signal: AbortSignal.timeout(8000),
        })
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        const livePatrols = await res.json()
        if (!Array.isArray(livePatrols) || livePatrols.length === 0) return

        setPatrolStates(prev => {
          const updated = [...prev]
          livePatrols.forEach((lp, i) => {
            if (i >= updated.length) return
            // Don't override an actively simulated Responding/AtScene state
            const sim = updated[i]
            if (sim.status === 'Responding' || sim.status === 'AtScene') return
            const raw = (lp.status ?? '').toLowerCase()
            const mapped = raw === 'responding' ? 'Responding'
              : raw === 'at_scene' || raw === 'at scene' ? 'AtScene'
              : 'Patrolling'
            if (sim.status !== mapped) {
              updated[i] = { ...sim, status: mapped }
            }
          })
          return updated
        })
      } catch {
        // Backend unavailable — simulation continues unaffected
      }
    }

    syncStatuses()
    const id = setInterval(syncStatuses, 30_000)
    return () => clearInterval(id)
  }, [])

  // ── Dispatch nearest patrol to SOS location ───────────────────────────────
  const dispatchPatrol = useCallback((sosLocation) => {
    const nearest = findNearestPatrol(patrolRef.current, sosLocation)
    if (!nearest) return null

    setPatrolStates(prev =>
      prev.map(p =>
        p.id === nearest.id
          ? { ...p, status: 'Responding', respondingTo: sosLocation, atSceneStart: null }
          : p
      )
    )
    return nearest.name
  }, [])

  return { patrolStates, dispatchPatrol }
}
import { useState, useEffect, useRef } from 'react'
import { ENDPOINTS } from '../config/api'

/**
 * Fetches live patrol data from /patrols every 30s.
 * Returns { patrolStates } — each entry has id, name, vehicle, status, position.
 * All patrols default to 'Patrolling' (blue) unless the API says otherwise.
 */
export function useLivePatrols() {
  const [patrolStates, setPatrolStates] = useState([])
  const intervalRef = useRef(null)

  const normaliseStatus = (raw) => {
    const s = (raw ?? '').toLowerCase().replace(/[_\s]+/g, ' ').trim()
    if (s === 'responding' || s === 'on the way' || s === 'en route') return 'Responding'
    if (s === 'at scene' || s === 'atscene') return 'AtScene'
    return 'Patrolling'
  }

  const fetchPatrols = async () => {
    try {
      const res = await fetch(ENDPOINTS.patrolsList, {
        signal: AbortSignal.timeout(8000),
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()
      // Don't bail on empty — keep existing state if API returns nothing
      if (!Array.isArray(data)) return

      // Spread patrols across zones — index 0→T.Nagar, 1→Mylapore, 2→Anna Nagar
      const ZONE_STARTS = [
        { lat: 13.0418, lng: 80.2341 },
        { lat: 13.0339, lng: 80.2619 },
        { lat: 13.0850, lng: 80.2101 },
      ]
      setPatrolStates(data.map((item, idx) => ({
        id:      item.patrol_id ?? item.id ?? `P-${idx + 1}`,
        name:    item.officer   ?? item.name ?? 'Officer',
        vehicle: item.vehicle   ?? 'TN-01-PA-XXXX',
        zone:    item.zone      ?? '',
        status:  normaliseStatus(item.status),
        position: ZONE_STARTS[idx % ZONE_STARTS.length],
      })))
    } catch {
      // Keep existing state on error
    }
  }

  // Update a single patrol's status (e.g. after SOS dispatch)
  const updatePatrolStatus = (patrolId, newStatus) => {
    setPatrolStates(prev =>
      prev.map(p => p.id === patrolId ? { ...p, status: normaliseStatus(newStatus) } : p)
    )
  }

  useEffect(() => {
    fetchPatrols()
    intervalRef.current = setInterval(fetchPatrols, 30_000)
    return () => clearInterval(intervalRef.current)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return { patrolStates, updatePatrolStatus }
}
import { useState, useEffect, useRef } from 'react'
import { ENDPOINTS } from '../config/api'
import { ZONES } from '../constants/zones'

// Build a pincode → area name lookup from ZONES
const _pincodeToName = {}
ZONES.forEach(z => { _pincodeToName[z.c] = z.n })

// Resolve a raw zone_name/pincode string to a human-readable area name.
// If zone_name looks like a pincode (all digits), look it up; otherwise use as-is.
function resolveZoneName(zone_name, pincode) {
  const raw = zone_name ?? pincode ?? null
  if (!raw) return 'Unknown Zone'
  const str = String(raw).trim()
  // If it's a 6-digit pincode, look up the area name
  if (/^\d{6}$/.test(str)) return _pincodeToName[str] ? `${_pincodeToName[str]} (${str})` : str
  return str
}

/**
 * Polls /sos/live every 10s.
 * Returns only real API items — no simulation, no fallback mock entries.
 * If the API returns empty, events = [] and the panel shows "No active SOS alerts".
 */
export function useSosEvents() {
  const [events, setEvents] = useState([])
  const [total,  setTotal]  = useState(0)
  const seenIdsRef = useRef(new Set())

  useEffect(() => {
    const pollSos = async () => {
      try {
        const res = await fetch(ENDPOINTS.sosLive, {
          signal: AbortSignal.timeout(8000),
        })
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        const items = await res.json()
        if (!Array.isArray(items)) return

        const newEvs = items
          .filter(item => !seenIdsRef.current.has(item.sos_id))
          .map(item => {
            seenIdsRef.current.add(item.sos_id)
            return {
              id:      item.sos_id,
              name:    resolveZoneName(item.zone_name, item.pincode),
              risk:    (item.risk_level ?? 'HIGH').toUpperCase(),
              ts:      new Date(item.created_at ?? Date.now()),
              status:  item.status === 'resolved'   ? 'resolved'
                     : item.status === 'dispatched' ? 'resolving'
                     : 'dispatched',
              lat:     item.lat ?? item.latitude  ?? null,
              lng:     item.lng ?? item.longitude ?? null,
              pincode: item.pincode ?? null,
              sos_id:  item.sos_id,
            }
          })

        if (newEvs.length > 0) {
          setEvents(prev => [...newEvs, ...prev].slice(0, 20))
          setTotal(t => t + newEvs.length)
        }

        // Also update status of existing events from the full list
        setEvents(prev => prev.map(ev => {
          const live = items.find(i => i.sos_id === ev.sos_id)
          if (!live) return ev
          const status = live.status === 'resolved'   ? 'resolved'
                       : live.status === 'dispatched' ? 'resolving'
                       : 'dispatched'
          return { ...ev, status }
        }))
      } catch {
        // Backend unavailable — keep current events, don't add mocks
      }
    }

    pollSos()
    const id = setInterval(pollSos, 10_000)
    return () => clearInterval(id)
  }, [])

  return { events, total }
}
export const PATROL_ROUTES = [
  { id: "P001", name: "Unit Alpha",   zone: "T. Nagar",       color: "#00e5ff",
    waypoints: [[13.0418,80.2341],[13.0401,80.2367],[13.0389,80.2398],[13.0412,80.2421],[13.0435,80.2389],[13.0418,80.2341]] },
  { id: "P002", name: "Unit Bravo",   zone: "Mylapore",       color: "#00e5ff",
    waypoints: [[13.0339,80.2619],[13.0318,80.2645],[13.0298,80.2630],[13.0311,80.2601],[13.0334,80.2588],[13.0339,80.2619]] },
  { id: "P003", name: "Unit Charlie", zone: "Anna Nagar",     color: "#00e5ff",
    waypoints: [[13.0850,80.2101],[13.0871,80.2134],[13.0889,80.2112],[13.0868,80.2079],[13.0845,80.2068],[13.0850,80.2101]] },
  { id: "P004", name: "Unit Delta",   zone: "Adyar",          color: "#00e5ff",
    waypoints: [[13.0012,80.2565],[13.0034,80.2589],[13.0056,80.2571],[13.0041,80.2543],[13.0018,80.2531],[13.0012,80.2565]] },
  { id: "P005", name: "Unit Echo",    zone: "Velachery",      color: "#00e5ff",
    waypoints: [[12.9815,80.2180],[12.9838,80.2209],[12.9856,80.2191],[12.9843,80.2162],[12.9821,80.2151],[12.9815,80.2180]] },
  { id: "P006", name: "Unit Foxtrot", zone: "Thiruvanmiyur",  color: "#00e5ff",
    waypoints: [[12.9830,80.2590],[12.9852,80.2618],[12.9871,80.2601],[12.9858,80.2573],[12.9835,80.2560],[12.9830,80.2590]] },
  { id: "P007", name: "Unit Golf",    zone: "Kodambakkam",    color: "#00e5ff",
    waypoints: [[13.0501,80.2289],[13.0523,80.2314],[13.0541,80.2298],[13.0528,80.2270],[13.0505,80.2258],[13.0501,80.2289]] },
  { id: "P008", name: "Unit Hotel",   zone: "Guindy",         color: "#00e5ff",
    waypoints: [[13.0101,80.2201],[13.0123,80.2228],[13.0145,80.2212],[13.0130,80.2185],[13.0108,80.2172],[13.0101,80.2201]] },
  { id: "P009", name: "Unit India",   zone: "Perambur",       color: "#00e5ff",
    waypoints: [[13.1120,80.2390],[13.1142,80.2415],[13.1161,80.2398],[13.1148,80.2370],[13.1125,80.2358],[13.1120,80.2390]] },
  { id: "P010", name: "Unit Juliet",  zone: "Chromepet",      color: "#00e5ff",
    waypoints: [[12.9520,80.1398],[12.9543,80.1425],[12.9562,80.1408],[12.9548,80.1380],[12.9525,80.1368],[12.9520,80.1398]] },
  { id: "P011", name: "Unit Kilo",    zone: "Porur",          color: "#00e5ff",
    waypoints: [[13.0335,80.1589],[13.0358,80.1615],[13.0378,80.1598],[13.0362,80.1570],[13.0339,80.1558],[13.0335,80.1589]] },
  { id: "P012", name: "Unit Lima",    zone: "Sholinganallur", color: "#00e5ff",
    waypoints: [[12.9010,80.2273],[12.9033,80.2299],[12.9051,80.2283],[12.9038,80.2255],[12.9015,80.2243],[12.9010,80.2273]] },
]
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    include: ['leaflet', 'leaflet.heat'],
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
      },
    },
  },
});
const API_BASE = import.meta.env.VITE_API_URL ?? '';

export const ENDPOINTS = {
  predict:   `${API_BASE}/predict`,
  sosEvents: `${API_BASE}/sos/events`,
  patrols:   `${API_BASE}/patrols`,
  stats:     `${API_BASE}/stats`,
};

export const ZONES = [
  { c: '600001', n: 'Parrys',          lat: 13.0908, lon: 80.2866, r: 'HIGH' },
  { c: '600006', n: 'Vepery',          lat: 13.0900, lon: 80.2757, r: 'HIGH' },
  { c: '600007', n: 'Perambur',        lat: 13.1186, lon: 80.2487, r: 'HIGH' },
  { c: '600058', n: 'Royapuram',       lat: 13.1127, lon: 80.2966, r: 'HIGH' },
  { c: '600081', n: 'Manali',          lat: 13.1675, lon: 80.2617, r: 'HIGH' },
  { c: '600002', n: 'Park Town',       lat: 13.0827, lon: 80.2707, r: 'MEDIUM' },
  { c: '600003', n: 'Triplicane',      lat: 13.0569, lon: 80.2787, r: 'MEDIUM' },
  { c: '600004', n: 'Chintadripet',    lat: 13.0715, lon: 80.2740, r: 'MEDIUM' },
  { c: '600005', n: 'Choolai',         lat: 13.1013, lon: 80.2615, r: 'MEDIUM' },
  { c: '600008', n: 'Washermanpet',    lat: 13.1075, lon: 80.2902, r: 'MEDIUM' },
  { c: '600009', n: 'Aminjikarai',     lat: 13.0750, lon: 80.2193, r: 'MEDIUM' },
  { c: '600010', n: 'Kilpauk',         lat: 13.0827, lon: 80.2354, r: 'MEDIUM' },
  { c: '600011', n: 'Egmore',          lat: 13.0732, lon: 80.2609, r: 'MEDIUM' },
  { c: '600012', n: 'Chetpet',         lat: 13.0750, lon: 80.2354, r: 'MEDIUM' },
  { c: '600013', n: 'Nungambakkam',    lat: 13.0569, lon: 80.2425, r: 'MEDIUM' },
  { c: '600014', n: 'Alwarpet',        lat: 13.0339, lon: 80.2553, r: 'LOW' },
  { c: '600015', n: 'Mylapore',        lat: 13.0339, lon: 80.2707, r: 'LOW' },
  { c: '600017', n: 'Adyar',           lat: 13.0067, lon: 80.2570, r: 'LOW' },
  { c: '600018', n: 'Kodambakkam',     lat: 13.0521, lon: 80.2193, r: 'LOW' },
  { c: '600019', n: 'Saligramam',      lat: 13.0475, lon: 80.2030, r: 'LOW' },
  { c: '600020', n: 'Vadapalani',      lat: 13.0521, lon: 80.2118, r: 'LOW' },
  { c: '600024', n: 'Velachery',       lat: 12.9815, lon: 80.2209, r: 'LOW' },
  { c: '600028', n: 'Besant Nagar',    lat: 12.9995, lon: 80.2666, r: 'LOW' },
  { c: '600029', n: 'Thiruvanmiyur',   lat: 12.9845, lon: 80.2657, r: 'LOW' },
  { c: '600032', n: 'T Nagar',         lat: 13.0350, lon: 80.2323, r: 'LOW' },
  { c: '600033', n: 'Virugambakkam',   lat: 13.0521, lon: 80.2030, r: 'LOW' },
  { c: '600034', n: 'Ashok Nagar',     lat: 13.0339, lon: 80.2193, r: 'LOW' },
  { c: '600035', n: 'KK Nagar',        lat: 13.0402, lon: 80.2091, r: 'LOW' },
  { c: '600036', n: 'Anna Nagar West', lat: 13.0883, lon: 80.2105, r: 'LOW' },
  { c: '600040', n: 'Anna Nagar',      lat: 13.0850, lon: 80.2101, r: 'LOW' },
  { c: '600042', n: 'Mogappair',       lat: 13.0883, lon: 80.1762, r: 'LOW' },
  { c: '600044', n: 'Porur',           lat: 13.0339, lon: 80.1575, r: 'LOW' },
  { c: '600045', n: 'Ramapuram',       lat: 13.0237, lon: 80.1762, r: 'LOW' },
  { c: '600050', n: 'Pallavaram',      lat: 12.9673, lon: 80.1501, r: 'LOW' },
  { c: '600053', n: 'Chromepet',       lat: 12.9515, lon: 80.1438, r: 'LOW' },
  { c: '600056', n: 'Perungudi',       lat: 12.9625, lon: 80.2387, r: 'LOW' },
  { c: '600061', n: 'Sholinganallur',  lat: 12.9000, lon: 80.2277, r: 'LOW' },
  { c: '600064', n: 'Medavakkam',      lat: 12.9240, lon: 80.1958, r: 'LOW' },
  { c: '600073', n: 'Selaiyur',        lat: 12.9150, lon: 80.1501, r: 'LOW' },
  { c: '600078', n: 'Ambattur',        lat: 13.1144, lon: 80.1606, r: 'LOW' },
  { c: '600082', n: 'Puzhal',          lat: 13.1675, lon: 80.2355, r: 'LOW' },
  { c: '600083', n: 'Madhavaram',      lat: 13.1483, lon: 80.2355, r: 'LOW' },
  { c: '600099', n: 'Kolathur',        lat: 13.1186, lon: 80.2091, r: 'LOW' },
  { c: '600118', n: 'Perumbakkam',     lat: 12.9065, lon: 80.1958, r: 'LOW' },
];

export const ROAD_WAYPOINTS = [
  { name: 'North Coastal Loop',   pts: [[13.1127,80.2966],[13.1186,80.2487],[13.1483,80.2355],[13.1675,80.2617],[13.1127,80.2966]] },
  { name: 'Central City Loop',    pts: [[13.0827,80.2707],[13.0732,80.2609],[13.0569,80.2787],[13.0715,80.2740],[13.0827,80.2707]] },
  { name: 'Anna Nagar Loop',      pts: [[13.0883,80.2105],[13.0850,80.2101],[13.0750,80.2354],[13.0827,80.2354],[13.0883,80.2105]] },
  { name: 'South Chennai Loop',   pts: [[13.0067,80.2570],[12.9995,80.2666],[12.9845,80.2657],[12.9815,80.2209],[13.0067,80.2570]] },
  { name: 'West Chennai Loop',    pts: [[13.0521,80.2193],[13.0475,80.2030],[13.0339,80.2193],[13.0402,80.2091],[13.0521,80.2193]] },
  { name: 'Porur-Ramapuram Loop', pts: [[13.0339,80.1575],[13.0237,80.1762],[12.9673,80.1501],[12.9515,80.1438],[13.0339,80.1575]] },
  { name: 'Ambattur Loop',        pts: [[13.1144,80.1606],[13.0883,80.1762],[13.0521,80.2030],[13.0883,80.2105],[13.1144,80.1606]] },
];

export const PATROL_UNITS = [
  { id: 'P-01', vehicle: 'TN-01-PA-1234', officers: ['SI Priya Kumari',  'Const. Rajan M'],   zone: 'Parrys',         status: 'patrolling', contact: '+91-44-2345-6701', routeIdx: 0, wayptIdx: 0 },
  { id: 'P-02', vehicle: 'TN-01-PA-1235', officers: ['SI Meena Devi',    'Const. Selvam K'],  zone: 'Royapuram',      status: 'patrolling', contact: '+91-44-2345-6702', routeIdx: 0, wayptIdx: 1 },
  { id: 'P-03', vehicle: 'TN-01-PA-1236', officers: ['SI Kavitha R',     'Const. Murugan S'], zone: 'Perambur',       status: 'patrolling', contact: '+91-44-2345-6703', routeIdx: 1, wayptIdx: 0 },
  { id: 'P-04', vehicle: 'TN-01-PA-1237', officers: ['SI Lakshmi V',     'Const. Senthil P'], zone: 'Vepery',         status: 'patrolling', contact: '+91-44-2345-6704', routeIdx: 1, wayptIdx: 2 },
  { id: 'P-05', vehicle: 'TN-01-PA-1238', officers: ['SI Divya S',       'Const. Arjun T'],   zone: 'Egmore',         status: 'patrolling', contact: '+91-44-2345-6705', routeIdx: 2, wayptIdx: 0 },
  { id: 'P-06', vehicle: 'TN-01-PA-1239', officers: ['SI Sangeetha N',   'Const. Karthi R'],  zone: 'Kilpauk',        status: 'patrolling', contact: '+91-44-2345-6706', routeIdx: 2, wayptIdx: 2 },
  { id: 'P-07', vehicle: 'TN-01-PA-1240', officers: ['SI Anitha B',      'Const. Vijay M'],   zone: 'T Nagar',        status: 'patrolling', contact: '+91-44-2345-6707', routeIdx: 3, wayptIdx: 0 },
  { id: 'P-08', vehicle: 'TN-01-PA-1241', officers: ['SI Rekha C',       'Const. Suresh G'],  zone: 'Anna Nagar',     status: 'patrolling', contact: '+91-44-2345-6708', routeIdx: 3, wayptIdx: 1 },
  { id: 'P-09', vehicle: 'TN-01-PA-1242', officers: ['SI Malathi D',     'Const. Prakash N'], zone: 'Adyar',          status: 'patrolling', contact: '+91-44-2345-6709', routeIdx: 4, wayptIdx: 0 },
  { id: 'P-10', vehicle: 'TN-01-PA-1243', officers: ['SI Padma L',       'Const. Ramesh V'],  zone: 'Velachery',      status: 'patrolling', contact: '+91-44-2345-6710', routeIdx: 4, wayptIdx: 2 },
  { id: 'P-11', vehicle: 'TN-01-PA-1244', officers: ['SI Geetha M',      'Const. Kumar A'],   zone: 'Porur',          status: 'patrolling', contact: '+91-44-2345-6711', routeIdx: 5, wayptIdx: 0 },
  { id: 'P-12', vehicle: 'TN-01-PA-1245', officers: ['SI Nithya P',      'Const. Balu S'],    zone: 'Ambattur',       status: 'patrolling', contact: '+91-44-2345-6712', routeIdx: 6, wayptIdx: 0 },
  { id: 'P-13', vehicle: 'TN-01-PA-1246', officers: ['SI Vimala R',      'Const. Dinesh K'],  zone: 'Sholinganallur', status: 'patrolling', contact: '+91-44-2345-6713', routeIdx: 3, wayptIdx: 3 },
  { id: 'P-14', vehicle: 'TN-01-PA-1247', officers: ['SI Hema S',        'Const. Mohan T'],   zone: 'Medavakkam',     status: 'patrolling', contact: '+91-44-2345-6714', routeIdx: 5, wayptIdx: 1 },
  { id: 'P-15', vehicle: 'TN-01-PA-1248', officers: ['SI Saranya B',     'Const. Ganesh V'],  zone: 'Kolathur',       status: 'patrolling', contact: '+91-44-2345-6715', routeIdx: 6, wayptIdx: 2 },
  { id: 'P-16', vehicle: 'TN-01-PA-1249', officers: ['SI Deepa M',       'Const. Siva R'],    zone: 'Selaiyur',       status: 'patrolling', contact: '+91-44-2345-6716', routeIdx: 5, wayptIdx: 2 },
  { id: 'P-17', vehicle: 'TN-01-PA-1250', officers: ['SI Jaya K',        'Const. Karthik N'], zone: 'Perungudi',      status: 'patrolling', contact: '+91-44-2345-6717', routeIdx: 4, wayptIdx: 1 },
  { id: 'P-18', vehicle: 'TN-01-PA-1251', officers: ['SI Radha P',       'Const. Balaji S'],  zone: 'Puzhal',         status: 'patrolling', contact: '+91-44-2345-6718', routeIdx: 0, wayptIdx: 3 },
];
import { useState, useEffect, useCallback, useRef } from 'react';
import axios from 'axios';
import { ENDPOINTS, ZONES } from '../config/api';

/**
 * Returns { data, loading, error, refresh }
 *
 * data shape:
 *   zoneRisks  : { [pincode]: { riskLevel, riskIndex, confidence } } | null
 *   sosEvents  : Array<{ id, location, risk, timestamp, status }>   | null
 *   patrols    : { patrolling, responding, atScene, units }          | null
 *   stats      : { sosToday, avgResponseTime }                       | null
 */
export function useRakshakData() {
  const [data, setData]       = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);

  const abortRef = useRef(null);

  const apiFailed = useRef(false);

  const fetchZoneRisks = useCallback(async () => {
    const now       = new Date();
    const hour      = now.getHours();
    const dow       = now.getDay();
    const isnight   = hour < 6 || hour >= 20 ? 1 : 0;
    const isweekend = dow === 0 || dow === 6  ? 1 : 0;

    // Fallback: derive a deterministic mock risk from the static zone data
    const mockResult = () => {
      const result = {};
      ZONES.forEach((z) => {
        const riskIndex = z.r === 'HIGH' ? 0.85 : z.r === 'MEDIUM' ? 0.52 : 0.15;
        result[z.c] = { riskLevel: z.r, riskIndex, confidence: 0.5 };
      });
      return result;
    };

    // If the API already failed this session, skip and return mock immediately
    if (apiFailed.current) return mockResult();

    const settled = await Promise.allSettled(
      ZONES.map((z) =>
        axios
          .post(
            ENDPOINTS.predict,
            { lat: z.lat, lon: z.lon, hour, dayofweek: dow, isnight, isweekend },
            { signal: AbortSignal.timeout(5000), timeout: 5000 }
          )
          .then((r) => {
            if (r.status === 503) throw new Error('503');
            return { code: z.c, data: r.data };
          })
      )
    );

    // Check if every single call failed (API is down)
    const allFailed = settled.every((r) => r.status === 'rejected');
    if (allFailed) {
      if (!apiFailed.current) {
        console.warn('Prediction API unavailable, using fallback data');
        apiFailed.current = true;
      }
      return mockResult();
    }

    const result = {};
    settled.forEach((r, i) => {
      if (r.status === 'fulfilled') {
        result[ZONES[i].c] = r.value.data;
      } else {
        // Individual zone failed — fill in with static fallback
        const z = ZONES[i];
        result[z.c] = {
          riskLevel: z.r,
          riskIndex: z.r === 'HIGH' ? 0.85 : z.r === 'MEDIUM' ? 0.52 : 0.15,
          confidence: 0.5,
        };
      }
    });
    return result;
  }, []);

  const refresh = useCallback(async () => {
    if (abortRef.current) abortRef.current.abort();
    abortRef.current = new AbortController();

    setError(null);

    const [zoneResult, sosResult, patrolResult, statsResult] =
      await Promise.allSettled([
        fetchZoneRisks(),
        axios.get(ENDPOINTS.sosEvents, { signal: AbortSignal.timeout(5000) }).then((r) => r.data),
        axios.get(ENDPOINTS.patrols,   { signal: AbortSignal.timeout(5000) }).then((r) => r.data),
        axios.get(ENDPOINTS.stats,     { signal: AbortSignal.timeout(5000) }).then((r) => r.data),
      ]);

    setData({
      zoneRisks:  zoneResult.status   === 'fulfilled' ? zoneResult.value   : null,
      sosEvents:  sosResult.status    === 'fulfilled' ? sosResult.value    : null,
      patrols:    patrolResult.status === 'fulfilled' ? patrolResult.value : null,
      stats:      statsResult.status  === 'fulfilled' ? statsResult.value  : null,
    });

    if (zoneResult.status === 'rejected') {
      setError(zoneResult.reason?.message ?? 'Failed to load zone data');
    }

    setLoading(false);
  }, [fetchZoneRisks]);

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, 60_000);
    return () => {
      clearInterval(id);
      abortRef.current?.abort();
    };
  }, [refresh]);

  return { data, loading, error, refresh };
}
const fs = require('fs')
const path = require('path')

const KML_FILE = path.join(__dirname, 'rakshak-dashboard/public/Final_Chennai_Pincode.kml')
const OUT_FILE = path.join(__dirname, 'rakshak-dashboard/public/chennai-zones-fixed.geojson')

// Offsets derived from Tondiarpet S.O. (600081) first vertex vs known centre
const LAT_OFFSET = -0.017923
const LNG_OFFSET = -0.006134

const kmlText = fs.readFileSync(KML_FILE, 'utf8')

// Minimal XML parser using regex — sufficient for this well-structured KML
function getTagContent(text, tag) {
  const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'g')
  const results = []
  let m
  while ((m = re.exec(text)) !== null) results.push(m[1])
  return results
}

function getAttrContent(text, tag, attr) {
  const re = new RegExp(`<${tag}[^>]*name=["']${attr}["'][^>]*>([\\s\\S]*?)<\\/${tag}>`)
  const m = re.exec(text)
  return m ? m[1].trim() : null
}

const placemarks = []
const pmRe = /<Placemark[\s\S]*?<\/Placemark>/g
let pm
while ((pm = pmRe.exec(kmlText)) !== null) {
  const block = pm[0]

  // Extract pincode from SimpleData name="Pincode"
  const pincodeMatch = block.match(/<SimpleData name="Pincode">(.*?)<\/SimpleData>/)
  const pincode = pincodeMatch ? pincodeMatch[1].trim() : null

  const officeMatch = block.match(/<SimpleData name="Office_Name">(.*?)<\/SimpleData>/)
  const officeName = officeMatch ? officeMatch[1].trim() : null

  // Extract outer boundary coordinates (skip holes for simplicity)
  const coordsMatch = block.match(/<outerBoundaryIs>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>/)
  if (!coordsMatch || !pincode) continue

  const rawCoords = coordsMatch[1].trim().split(/\s+/).filter(c => c.includes(','))
  const coords = rawCoords.map(c => {
    const parts = c.split(',')
    const lng = parseFloat(parts[0]) + LNG_OFFSET
    const lat = parseFloat(parts[1]) + LAT_OFFSET
    return [lng, lat]
  }).filter(p => !isNaN(p[0]) && !isNaN(p[1]))

  if (coords.length < 3) continue

  // GeoJSON polygon rings must close
  if (coords[0][0] !== coords[coords.length - 1][0] || coords[0][1] !== coords[coords.length - 1][1]) {
    coords.push(coords[0])
  }

  placemarks.push({
    type: 'Feature',
    properties: { pincode, officeName },
    geometry: { type: 'Polygon', coordinates: [coords] },
  })
}

const geojson = { type: 'FeatureCollection', features: placemarks }
fs.writeFileSync(OUT_FILE, JSON.stringify(geojson))

console.log(`Converted ${placemarks.length} polygons`)
console.log(`LAT_OFFSET applied: ${LAT_OFFSET}`)
console.log(`LNG_OFFSET applied: ${LNG_OFFSET}`)
console.log(`Output: ${OUT_FILE}`)
// Stub for geocoding package on web — geocoding is not supported on web.
// The kIsWeb guard in sentinel_controller.dart ensures this is never called.

class Placemark {
  final String? postalCode;
  final String? subLocality;
  final String? locality;
  const Placemark({this.postalCode, this.subLocality, this.locality});
}

Future<List<Placemark>> placemarkFromCoordinates(
  double latitude,
  double longitude, {
  String? localeIdentifier,
}) async {
  return [];
}
import '../models/risk_score.dart';
import '../models/user_profile.dart';
import '../models/emergency_contact.dart';

/// Stub data for development and testing
class StubData {
  StubData._();

  // Stub delay for simulating API calls
  static const Duration apiDelay = Duration(milliseconds: 800);

  // Stub Risk Scores
  static final RiskScore lowRisk = RiskScore(
    score: 25,
    level: RiskLevel.low,
    location: 'T. Nagar, Chennai',
    timestamp: DateTime.now(),
    factors: ['Well-lit area', 'High foot traffic', 'Police presence'],
  );

  static final RiskScore mediumRisk = RiskScore(
    score: 55,
    level: RiskLevel.medium,
    location: 'Adyar, Chennai',
    timestamp: DateTime.now(),
    factors: ['Moderate lighting', 'Some activity', 'Residential area'],
  );

  static final RiskScore highRisk = RiskScore(
    score: 78,
    level: RiskLevel.high,
    location: 'Isolated Street, Chennai',
    timestamp: DateTime.now(),
    factors: ['Poor lighting', 'Low activity', 'No surveillance'],
  );

  static final RiskScore criticalRisk = RiskScore(
    score: 92,
    level: RiskLevel.critical,
    location: 'Dark Alley, Chennai',
    timestamp: DateTime.now(),
    factors: ['No lighting', 'Deserted', 'High crime history'],
  );

  // Stub User Profile
  static final UserProfile defaultUser = UserProfile(
    id: 'user_001',
    name: 'Priya Kumar',
    phone: '+91 98765 43210',
    email: 'priya.kumar@example.com',
    emergencyContacts: [
      EmergencyContact(
        id: 'contact_001',
        name: 'Raj Kumar (Father)',
        phone: '+91 98765 43211',
        relationship: 'Father',
      ),
      EmergencyContact(
        id: 'contact_002',
        name: 'Lakshmi Kumar (Mother)',
        phone: '+91 98765 43212',
        relationship: 'Mother',
      ),
      EmergencyContact(
        id: 'contact_003',
        name: 'Arun Kumar (Brother)',
        phone: '+91 98765 43213',
        relationship: 'Brother',
      ),
    ],
  );

  // Stub Emergency Contacts
  static final List<EmergencyContact> emergencyContacts = [
    EmergencyContact(
      id: 'contact_001',
      name: 'Raj Kumar (Father)',
      phone: '+91 98765 43211',
      relationship: 'Father',
    ),
    EmergencyContact(
      id: 'contact_002',
      name: 'Lakshmi Kumar (Mother)',
      phone: '+91 98765 43212',
      relationship: 'Mother',
    ),
    EmergencyContact(
      id: 'contact_003',
      name: 'Arun Kumar (Brother)',
      phone: '+91 98765 43213',
      relationship: 'Brother',
    ),
  ];

  // Stub SOS Status
  static const Map<String, dynamic> sosActive = {
    'status': 'active',
    'timestamp': '2024-01-15T20:30:00Z',
    'location': 'T. Nagar, Chennai',
    'contacts_notified': 3,
  };

  static const Map<String, dynamic> sosSecured = {
    'status': 'secured',
    'timestamp': '2024-01-15T20:35:00Z',
    'location': 'T. Nagar, Chennai',
    'response_time': '5 minutes',
  };
}
/// Chennai pincode → ML model area_encoded mapping (unchanged)
const pincodeToAreaEncoded = <int, int>{
  600001: 19, 600002: 27, 600003: 18, 600004: 14, 600005: 7,
  600006: 6,  600007: 20, 600008: 6,  600009: 11, 600010: 38,
  600011: 24, 600012: 34, 600013: 33, 600017: 29, 600018: 12,
  600019: 10, 600020: 2,  600021: 13, 600023: 41, 600024: 4,
  600028: 15, 600029: 1,  600032: 35, 600033: 25, 600034: 31,
  600035: 35, 600036: 28, 600040: 40, 600042: 32, 600044: 30,
  600045: 17, 600050: 3,  600053: 43, 600056: 23, 600061: 8,
  600064: 35, 600078: 36, 600081: 13, 600082: 13, 600083: 39,
  600090: 37, 600096: 16, 600099: 22, 600113: 26, 600118: 44,
  600119: 5,  600127: 21,
};

/// Chennai pincode → ML model neighborhood_encoded mapping (unchanged)
const pincodeToNeighborhoodEncoded = <int, int>{
  600001: 1, 600002: 1, 600003: 0, 600004: 0, 600005: 0,
  600006: 0, 600007: 3, 600008: 0, 600009: 5, 600010: 0,
  600011: 3, 600012: 3, 600013: 3, 600017: 0, 600018: 5,
  600019: 3, 600020: 5, 600021: 3, 600023: 3, 600024: 5,
  600028: 0, 600029: 5, 600032: 5, 600033: 4, 600034: 0,
  600035: 4, 600036: 4, 600040: 5, 600042: 4, 600044: 4,
  600045: 4, 600050: 5, 600053: 5, 600056: 5, 600061: 4,
  600064: 4, 600078: 5, 600081: 3, 600082: 3, 600083: 3,
  600090: 4, 600096: 2, 600099: 5, 600113: 2, 600118: 3,
  600119: 4, 600127: 2,
};

/// Valid Chennai pincodes accepted by Judge Mode
const validChennaiPincodes = <int>{
  600001, 600002, 600003, 600004, 600005, 600006, 600007,
  600008, 600009, 600010, 600011, 600012, 600013, 600015,
  600017, 600018, 600019, 600020, 600024, 600028, 600029,
  600032, 600033, 600034, 600035, 600036, 600040, 600042,
  600044, 600045, 600050, 600053, 600056, 600058, 600061,
  600064, 600078, 600081, 600082, 600083, 600090, 600096,
  600099, 600118,
};

/// Chennai pincode → human-readable area name (corrected)
const pincodeToAreaName = <int, String>{
  600001: 'Park Town',          600002: 'Sowcarpet',
  600003: 'Royapuram',          600004: 'Chintadripet',
  600005: 'Royapettah',         600006: 'Triplicane',
  600007: 'Egmore',             600008: 'Nungambakkam',
  600009: 'Kilpauk',            600010: 'Aminjikarai',
  600011: 'Perambur',           600012: 'Ashok Nagar',
  600013: 'Tiruvottiyur',       600015: 'Pattabiram',
  600017: 'T. Nagar',           600018: 'Abiramapuram',
  600019: 'Vyasarpadi',         600020: 'Saidapet',
  600024: 'Pallavaram',         600028: 'Adyar',
  600029: 'Besant Nagar',       600032: 'Alwarpet',
  600033: 'Valasaravakkam',     600034: 'Anna Nagar West',
  600035: 'Anna Nagar East',    600036: 'Arumbakkam',
  600040: 'Nanganallur',        600042: 'Velachery',
  600044: 'Perungudi',          600045: 'Thoraipakkam',
  600050: 'Mogappair',          600053: 'Villivakkam',
  600056: 'Kolathur',           600058: 'Royapuram',
  600061: 'Mugalivakkam',       600064: 'Medavakkam',
  600078: 'Ambattur',           600081: 'Manali',
  600082: 'Puzhal',             600083: 'Madhavaram',
  600090: 'Velachery',          600096: 'OMR',
  600099: 'Kundrathur',         600118: 'Perumbakkam',
};

/// Chennai pincode → latitude
const pincodeToLat = <int, double>{
  600001: 13.0827, 600002: 13.0674, 600003: 13.0900,
  600004: 13.0358, 600005: 13.0600, 600006: 13.0600,
  600007: 13.1200, 600008: 13.0750, 600009: 13.0850,
  600010: 13.0950, 600011: 13.1100, 600012: 13.1000,
  600013: 13.1150, 600015: 13.0496, 600017: 13.0496,
  600018: 13.0350, 600019: 13.1300, 600020: 13.0070,
  600024: 12.9800, 600028: 13.0200, 600029: 13.0800,
  600032: 13.0496, 600033: 13.0400, 600034: 13.0750,
  600035: 13.0496, 600036: 13.0100, 600040: 13.0700,
  600042: 12.9900, 600044: 12.9600, 600045: 12.9300,
  600050: 13.0750, 600053: 13.0850, 600056: 13.0496,
  600058: 13.1200, 600061: 12.9800, 600064: 12.9400,
  600078: 13.0496, 600081: 13.1100, 600082: 13.1050,
  600083: 13.0496, 600090: 12.9900, 600096: 13.0900,
  600099: 13.0900, 600118: 13.1000,
};

/// Chennai pincode → longitude
const pincodeToLon = <int, double>{
  600001: 80.2707, 600002: 80.2574, 600003: 80.2730,
  600004: 80.2674, 600005: 80.2780, 600006: 80.2496,
  600007: 80.2496, 600008: 80.2496, 600009: 80.2100,
  600010: 80.2496, 600011: 80.2496, 600012: 80.2674,
  600013: 80.2830, 600015: 80.2300, 600017: 80.2200,
  600018: 80.2300, 600019: 80.3000, 600020: 80.2574,
  600024: 80.2200, 600028: 80.2100, 600029: 80.2300,
  600032: 80.2100, 600033: 80.2200, 600034: 80.2574,
  600035: 80.2400, 600036: 80.2300, 600040: 80.2200,
  600042: 80.2300, 600044: 80.1300, 600045: 80.1300,
  600050: 80.2100, 600053: 80.1900, 600056: 80.1700,
  600058: 80.2900, 600061: 80.1800, 600064: 80.1300,
  600078: 80.2000, 600081: 80.3000, 600082: 80.2496,
  600083: 80.2150, 600090: 80.2200, 600096: 80.2200,
  600099: 80.2200, 600118: 80.2800,
};
/// API Endpoints for Rakshak Sentinel
class ApiEndpoints {
  ApiEndpoints._();

  static const _base =
      'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com';

  static const predict  = '$_base/predict';
  static const sos      = '$_base/sos';       // stub
  static const user     = '$_base/user';      // stub
  static const events   = '$_base/incidents'; // stub
}
/// Bilingual strings for Rakshak Sentinel (English & Tamil)
class AppStrings {
  AppStrings._();

  // Language codes
  static const String english = 'en';
  static const String tamil = 'ta';

  // Common
  static const Map<String, String> appName = {
    'en': 'Rakshak',
    'ta': 'ரட்சகன்',
  };

  static const Map<String, String> loading = {
    'en': 'Loading...',
    'ta': 'ஏற்றுகிறது...',
  };

  static const Map<String, String> error = {
    'en': 'Error',
    'ta': 'பிழை',
  };

  static const Map<String, String> retry = {
    'en': 'Retry',
    'ta': 'மீண்டும் முயற்சிக்கவும்',
  };

  static const Map<String, String> cancel = {
    'en': 'Cancel',
    'ta': 'ரத்து செய்',
  };

  static const Map<String, String> confirm = {
    'en': 'Confirm',
    'ta': 'உறுதிப்படுத்து',
  };

  // Auth
  static const Map<String, String> loginTitle = {
    'en': 'Welcome to Rakshak',
    'ta': 'ரட்சகனுக்கு வரவேற்கிறோம்',
  };

  static const Map<String, String> loginSubtitle = {
    'en': 'Your AI-powered safety companion',
    'ta': 'உங்கள் AI சக்தி கொண்ட பாதுகாப்பு துணை',
  };

  static const Map<String, String> phoneNumber = {
    'en': 'Phone Number',
    'ta': 'தொலைபேசி எண்',
  };

  static const Map<String, String> enterPhone = {
    'en': 'Enter your phone number',
    'ta': 'உங்கள் தொலைபேசி எண்ணை உள்ளிடவும்',
  };

  static const Map<String, String> sendOtp = {
    'en': 'Send OTP',
    'ta': 'OTP அனுப்பு',
  };

  static const Map<String, String> verifyOtp = {
    'en': 'Verify OTP',
    'ta': 'OTP சரிபார்க்கவும்',
  };

  // Sentinel (Dashboard)
  static const Map<String, String> sentinel = {
    'en': 'Sentinel',
    'ta': 'காவலன்',
  };

  static const Map<String, String> riskScore = {
    'en': 'Risk Score',
    'ta': 'ஆபத்து மதிப்பெண்',
  };

  static const Map<String, String> currentLocation = {
    'en': 'Current Location',
    'ta': 'தற்போதைய இடம்',
  };

  static const Map<String, String> nightWatch = {
    'en': 'Night Watch',
    'ta': 'இரவு காவல்',
  };

  static const Map<String, String> activateNightWatch = {
    'en': 'Activate Night Watch',
    'ta': 'இரவு காவலை செயல்படுத்து',
  };

  static const Map<String, String> sos = {
    'en': 'SOS',
    'ta': 'SOS',
  };

  static const Map<String, String> emergencySos = {
    'en': 'Emergency SOS',
    'ta': 'அவசர SOS',
  };

  // Intelligence
  static const Map<String, String> intelligence = {
    'en': 'Intelligence',
    'ta': 'நுண்ணறிவு',
  };

  static const Map<String, String> scanLocation = {
    'en': 'Scan Location',
    'ta': 'இடத்தை ஸ்கேன் செய்',
  };

  static const Map<String, String> analyzing = {
    'en': 'Analyzing...',
    'ta': 'பகுப்பாய்வு செய்கிறது...',
  };

  static const Map<String, String> riskAnalysis = {
    'en': 'Risk Analysis',
    'ta': 'ஆபத்து பகுப்பாய்வு',
  };

  // User Space
  static const Map<String, String> userSpace = {
    'en': 'User Space',
    'ta': 'பயனர் இடம்',
  };

  static const Map<String, String> profile = {
    'en': 'Profile',
    'ta': 'சுயவிவரம்',
  };

  static const Map<String, String> emergencyContacts = {
    'en': 'Emergency Contacts',
    'ta': 'அவசர தொடர்புகள்',
  };

  static const Map<String, String> settings = {
    'en': 'Settings',
    'ta': 'அமைப்புகள்',
  };

  // Risk Levels
  static const Map<String, String> riskLow = {
    'en': 'Low Risk',
    'ta': 'குறைந்த ஆபத்து',
  };

  static const Map<String, String> riskMedium = {
    'en': 'Medium Risk',
    'ta': 'நடுத்தர ஆபத்து',
  };

  static const Map<String, String> riskHigh = {
    'en': 'High Risk',
    'ta': 'அதிக ஆபத்து',
  };

  static const Map<String, String> riskCritical = {
    'en': 'Critical Risk',
    'ta': 'முக்கியமான ஆபத்து',
  };

  // Bottom Navigation
  static const Map<String, String> navSentinel = {
    'en': 'Sentinel',
    'ta': 'காவலன்',
  };

  static const Map<String, String> navAlerts = {
    'en': 'Alerts',
    'ta': 'எச்சரிக்கைகள்',
  };

  static const Map<String, String> navMap = {
    'en': 'Map',
    'ta': 'வரைபடம்',
  };

  static const Map<String, String> navUserSpace = {
    'en': 'Profile',
    'ta': 'சுயவிவரம்',
  };

  // Network / API errors
  static const Map<String, String> networkError = {
    'en': 'Network error. Check your connection and try again.',
    'ta': 'நெட்வொர்க் பிழை. உங்கள் இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  };

  static const Map<String, String> serverError = {
    'en': 'Server error. Please try again later.',
    'ta': 'சர்வர் பிழை. பின்னர் மீண்டும் முயற்சிக்கவும்.',
  };

  static const Map<String, String> timeoutError = {
    'en': 'Request timed out. Please try again.',
    'ta': 'கோரிக்கை நேர்முகமானது. மீண்டும் முயற்சிக்கவும்.',
  };

  // Helper method to get string by language
  static String get(Map<String, String> strings, String lang) {
    return strings[lang] ?? strings['en']!;
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings state
class SettingsState {
  final String languageCode;
  final bool isDarkMode;

  const SettingsState({
    this.languageCode = 'en',
    this.isDarkMode = true,
  });

  SettingsState copyWith({
    String? languageCode,
    bool? isDarkMode,
  }) {
    return SettingsState(
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setLanguage(String languageCode) {
    state = state.copyWith(languageCode: languageCode);
  }

  void toggleLanguage() {
    final newLang = state.languageCode == 'en' ? 'ta' : 'en';
    state = state.copyWith(languageCode: newLang);
  }

  void setDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
import 'risk_score.dart';

/// DTO for POST /predict response
class RiskScoreResponse {
  final String riskLevel;       // "Low" | "Medium" | "High"
  final int riskIndex;          // 0–100
  final double confidence;      // 0.0–1.0
  final Map<String, double> probabilities;

  const RiskScoreResponse({
    required this.riskLevel,
    required this.riskIndex,
    required this.confidence,
    required this.probabilities,
  });

  bool get isHigh   => riskLevel == 'High';
  bool get isMedium => riskLevel == 'Medium';
  bool get isLow    => riskLevel == 'Low';

  bool get isNightWatch =>
      DateTime.now().hour >= 22 && riskLevel == 'High';

  String get screenMode =>
      isNightWatch ? 'night_watch' : 'normal';

  factory RiskScoreResponse.fromJson(Map<String, dynamic> json) =>
      RiskScoreResponse(
        riskLevel: json['risk_level'] as String,
        riskIndex: (json['risk_index'] as num).toInt(),
        confidence: (json['confidence'] as num).toDouble(),
        probabilities: Map<String, double>.from(
          (json['probabilities'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ),
        ),
      );

  /// Maps to the app's RiskScore domain model
  RiskScore toRiskScore({String location = 'Current Location'}) {
    return RiskScore(
      score: riskIndex,
      level: _parseLevel(riskLevel),
      location: location,
      timestamp: DateTime.now(),
      factors: [
        'confidence: ${(confidence * 100).toStringAsFixed(0)}%',
        ...probabilities.entries.map(
          (e) => '${e.key}: ${(e.value * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  static RiskLevel _parseLevel(String level) {
    switch (level) {
      case 'High':
        return RiskLevel.high;
      case 'Medium':
        return RiskLevel.medium;
      case 'Low':
      default:
        return RiskLevel.low;
    }
  }
}
import 'emergency_contact.dart';

/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final List<EmergencyContact> emergencyContacts;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.emergencyContacts = const [],
  });

  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      emergencyContacts: (json['emergency_contacts'] as List?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
    };
  }

  /// Copy with
  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Risk level enumeration
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Risk score model
class RiskScore {
  final int score; // 0-100
  final RiskLevel level;
  final String location;
  final DateTime timestamp;
  final List<String> factors;

  const RiskScore({
    required this.score,
    required this.level,
    required this.location,
    required this.timestamp,
    required this.factors,
  });

  /// Get color based on risk level
  Color get color {
    switch (level) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.critical:
        return AppColors.riskCritical;
    }
  }

  /// Get label based on risk level
  String get label {
    switch (level) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  /// Get label in Tamil
  String get labelTa {
    switch (level) {
      case RiskLevel.low:
        return 'குறைந்த ஆபத்து';
      case RiskLevel.medium:
        return 'நடுத்தர ஆபத்து';
      case RiskLevel.high:
        return 'அதிக ஆபத்து';
      case RiskLevel.critical:
        return 'முக்கியமான ஆபத்து';
    }
  }

  /// Create from JSON
  factory RiskScore.fromJson(Map<String, dynamic> json) {
    return RiskScore(
      score: json['score'] as int,
      level: RiskLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => RiskLevel.low,
      ),
      location: json['location'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      factors: List<String>.from(json['factors'] as List),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level.name,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'factors': factors,
    };
  }

  /// Copy with
  RiskScore copyWith({
    int? score,
    RiskLevel? level,
    String? location,
    DateTime? timestamp,
    List<String>? factors,
  }) {
    return RiskScore(
      score: score ?? this.score,
      level: level ?? this.level,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      factors: factors ?? this.factors,
    );
  }
}
import '../constants/pincode_map.dart';

/// Request payload for POST /predict
class RiskPredictionRequest {
  final double latitude;
  final double longitude;
  final int pincode;
  final int hour;
  final int dayOfWeek;
  final int isWeekend;
  final int isNight;
  final int isEvening;
  final int isRushHour;
  final int reportingDelayMinutes;
  final int responseTimeMinutes;
  final int victimAge;
  final int signalCountLast7d;
  final int signalCountLast30d;
  final double signalDensityRatio;
  final int areaEncoded;
  final int neighborhoodEncoded;

  const RiskPredictionRequest({
    required this.latitude,
    required this.longitude,
    required this.pincode,
    required this.hour,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isNight,
    required this.isEvening,
    required this.isRushHour,
    this.reportingDelayMinutes = 20,
    this.responseTimeMinutes = 15,
    this.victimAge = 25,
    this.signalCountLast7d = 5,
    this.signalCountLast30d = 20,
    this.signalDensityRatio = 0.25,
    required this.areaEncoded,
    required this.neighborhoodEncoded,
  });

  /// Build from live GPS coordinates + pincode. Time derived from now.
  static RiskPredictionRequest fromGps(
    double lat,
    double lng,
    int pincode,
  ) {
    final now = DateTime.now();
    final hour = now.hour;
    final dow = now.weekday % 7; // 0=Sunday … 6=Saturday
    return RiskPredictionRequest(
      latitude: lat,
      longitude: lng,
      pincode: pincode,
      hour: hour,
      dayOfWeek: dow,
      isWeekend: (dow == 0 || dow == 6) ? 1 : 0,
      isNight: (hour >= 22 || hour <= 5) ? 1 : 0,
      isEvening: (hour >= 17 && hour <= 21) ? 1 : 0,
      isRushHour: [8, 9, 17, 18, 19].contains(hour) ? 1 : 0,
      areaEncoded: pincodeToAreaEncoded[pincode] ?? 0,
      neighborhoodEncoded: pincodeToNeighborhoodEncoded[pincode] ?? 0,
    );
  }

  /// Build for Judge Mode — hour is overridden by the slider.
  /// Uses pincode-specific coordinates when available.
  static RiskPredictionRequest forJudge(
    double lat,
    double lng,
    int pincode,
    int hour,
  ) {
    final now = DateTime.now();
    final dow = now.weekday % 7;
    // Use the pincode's known coordinates if available, else fall back to GPS
    final effectiveLat = pincodeToLat[pincode] ?? lat;
    final effectiveLng = pincodeToLon[pincode] ?? lng;
    return RiskPredictionRequest(
      latitude: effectiveLat,
      longitude: effectiveLng,
      pincode: pincode,
      hour: hour,
      dayOfWeek: dow,
      isWeekend: (dow == 0 || dow == 6) ? 1 : 0,
      isNight: (hour >= 22 || hour <= 5) ? 1 : 0,
      isEvening: (hour >= 17 && hour <= 21) ? 1 : 0,
      isRushHour: [8, 9, 17, 18, 19].contains(hour) ? 1 : 0,
      areaEncoded: pincodeToAreaEncoded[pincode] ?? 0,
      neighborhoodEncoded: pincodeToNeighborhoodEncoded[pincode] ?? 0,
    );
  }

  /// Legacy factory kept for backward compat with existing callers.
  factory RiskPredictionRequest.fromLocation({
    required double latitude,
    required double longitude,
    int pincode = 0,
  }) =>
      fromGps(latitude, longitude, pincode);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'pincode': pincode,
        'hour': hour,
        'day_of_week': dayOfWeek,
        'is_weekend': isWeekend,
        'is_night': isNight,
        'is_evening': isEvening,
        'is_rush_hour': isRushHour,
        'reporting_delay_minutes': reportingDelayMinutes,
        'response_time_minutes': responseTimeMinutes,
        'victim_age': victimAge,
        'signal_count_last_7d': signalCountLast7d,
        'signal_count_last_30d': signalCountLast30d,
        'signal_density_ratio': signalDensityRatio,
        'area_encoded': areaEncoded,
        'neighborhood_encoded': neighborhoodEncoded,
      };
}
/// Emergency contact model
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  /// Create from JSON
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  /// Copy with
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Rakshak Sentinel Theme — Stitch "Sentinel Glow" dark system
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBright,
        secondary: AppColors.accentBright,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Color(0xFF00382E),
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBright,
          foregroundColor: const Color(0xFF00382E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ghostBorder, width: 1),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ghostBorder, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accentBright, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentBright,
        unselectedItemColor: Color(0x66FFFFFF),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: 0,
      ),
    );
  }
}
import 'package:flutter/material.dart';

/// Rakshak Sentinel Color Palette — Stitch "Sentinel Glow" design system
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background       = Color(0xFF0A0F1E); // deep navy void
  static const Color surface          = Color(0xFF0E1322);
  static const Color surfaceContainer = Color(0xFF1A1F2F);
  static const Color surfaceHigh      = Color(0xFF25293A);
  static const Color surfaceHighest   = Color(0xFF2F3445);

  // Legacy aliases kept so untouched files compile
  static const Color primary          = Color(0xFF0A0F1E);
  static const Color primaryLight     = Color(0xFF1A1F2F);
  static const Color surfaceLight     = Color(0xFF1A1F2F);

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color accent           = Color(0xFF00D4B4); // electric teal seed
  static const Color accentBright     = Color(0xFF46F1CF); // primary on surface
  static const Color accentDark       = Color(0xFF00382E); // text on teal bg

  // ── Risk ─────────────────────────────────────────────────────────────────
  static const Color riskLow          = Color(0xFF22C55E);
  static const Color riskMedium       = Color(0xFFF59E0B);
  static const Color riskHigh         = Color(0xFFFF3B5C);
  static const Color riskCritical     = Color(0xFFFF3B5C);

  // ── Functional ───────────────────────────────────────────────────────────
  static const Color success          = Color(0xFF22C55E);
  static const Color warning          = Color(0xFFF59E0B);
  static const Color error            = Color(0xFFFF3B5C);
  static const Color alertRed         = Color(0xFF93000A); // danger bg
  static const Color info             = Color(0xFF46F1CF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFFFFFFFF);
  static const Color textSecondary    = Color(0xB3FFFFFF); // 70% white
  static const Color textTertiary     = Color(0x66FFFFFF); // 40% white

  // ── Borders ──────────────────────────────────────────────────────────────
  /// Ghost border — 1px, used on inputs only
  static const Color ghostBorder      = Color(0x263B4A45); // rgba(59,74,69,0.15)
  static const Color border           = Color(0xFF1F2937); // legacy alias
  static const Color divider          = Color(0xFF111827); // legacy alias

  // ── Shadows ──────────────────────────────────────────────────────────────
  /// Ambient shadow: #000 @ 40%, blur 40, spread -10
  static List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.40),
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];

  // ── Glassmorphism ─────────────────────────────────────────────────────────
  /// Floating elements: surfaceContainer @ 85% opacity + blur(20)
  static Color get glassBackground =>
      surfaceContainer.withValues(alpha: 0.85);
}
/// Rakshak Sentinel Spacing System — 8px base unit
class AppSpacing {
  AppSpacing._();

  static const double xs    = 4.0;
  static const double sm    = 8.0;
  static const double md    = 16.0;
  static const double lg    = 24.0;
  static const double xl    = 32.0;
  static const double xxl   = 48.0;
  static const double xxxl  = 64.0;

  // Semantic aliases
  static const double cardPadding   = 16.0;
  static const double screenPadding = 20.0;
  static const double buttonHeight  = 52.0;
  static const double iconSize      = 24.0;
  static const double iconSizeLg    = 32.0;

  // Radius — design system: 4px default, 6px slightly larger, NO pill
  static const double radiusSm  = 4.0;
  static const double radiusMd  = 6.0;
  static const double radiusLg  = 12.0; // cards only

  // Judge Mode panel
  static const double judgePanelWidth = 220.0;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Rakshak Sentinel Typography — Inter only, editorial scale
/// Rule: jump from very large to very small. No middle-ground sizes.
class AppText {
  AppText._();

  // ── Display ──────────────────────────────────────────────────────────────
  /// 3.5rem / 56px — critical status, risk score hero
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
    letterSpacing: -0.02 * 56,
  );

  /// 2.75rem / 44px — secondary hero text
  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
    letterSpacing: -0.02 * 44,
  );

  // Legacy aliases so existing code compiles
  static TextStyle display1 = displayLarge;
  static TextStyle display2 = displayMedium;

  // ── Headlines ─────────────────────────────────────────────────────────────
  /// 1.5rem / 24px — section headers
  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Legacy aliases
  static TextStyle h1 = GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.textPrimary, letterSpacing: -0.5);
  static TextStyle h2 = headlineSmall;
  static TextStyle h3 = GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary);
  static TextStyle h4 = GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary);

  // ── Body ──────────────────────────────────────────────────────────────────
  /// 0.875rem / 14px — standard body
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // Legacy aliases
  static TextStyle bodyLarge = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textPrimary);
  static TextStyle bodySmall = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);

  // ── Labels ────────────────────────────────────────────────────────────────
  /// 0.6875rem / 11px — uppercase caps, metadata, chips
  static TextStyle labelSmallCaps = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.textSecondary,
    letterSpacing: 0.05 * 11,
  );

  // Legacy aliases
  static TextStyle labelLarge  = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary, letterSpacing: 0.5);
  static TextStyle labelMedium = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textSecondary, letterSpacing: 0.5);
  static TextStyle labelSmall  = labelSmallCaps;

  // ── Buttons ───────────────────────────────────────────────────────────────
  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ── Misc ──────────────────────────────────────────────────────────────────
  static TextStyle caption = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);
  static TextStyle overline = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, height: 1.4, color: AppColors.textTertiary, letterSpacing: 1.5);
}
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Rakshak Card — Stitch spec
/// Flat surface, no elevation, no dividers.
/// Active state: surfaceHigh bg + 2px left teal strip.
class RkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool isActive;
  final double? borderRadius;

  const RkCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.isActive = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.radiusLg;
    final bg = isActive ? AppColors.surfaceHigh : (color ?? AppColors.surface);

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: isActive
            ? Border(
                left: BorderSide(color: AppColors.accentBright, width: 2),
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }
    return content;
  }
}
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_colors.dart';

/// Rakshak Label — Label Small Caps style by default
class RkLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;

  const RkLabel({
    super.key,
    required this.text,
    this.style,
    this.color,
    this.textAlign,
  });

  factory RkLabel.small(String text, {Color? color}) => RkLabel(
        text: text.toUpperCase(),
        style: AppText.labelSmallCaps,
        color: color,
      );

  factory RkLabel.medium(String text, {Color? color}) => RkLabel(
        text: text,
        style: AppText.labelMedium,
        color: color,
      );

  factory RkLabel.large(String text, {Color? color}) => RkLabel(
        text: text,
        style: AppText.labelLarge,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? AppText.labelSmallCaps).copyWith(
        color: color ?? AppColors.textSecondary,
      ),
      textAlign: textAlign,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'rk_button.dart';
import '../../features/intelligence/presentation/intelligence_controller.dart';
import '../../features/sentinel/presentation/sentinel_controller.dart';
import '../../core/models/risk_prediction_request.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Whether the Judge Mode panel is open.
final judgePanelOpenProvider = StateProvider<bool>((ref) => false);

/// Selected hour override (0–23).
final judgeHourProvider = StateProvider<int>((ref) => 14);

/// Selected pincode from the Judge Mode dropdown (null = nothing selected).
/// Read by score_screen.dart to show the simulation context banner.
final judgePincodeProvider = StateProvider<int?>((ref) => null);

// ── Constants ─────────────────────────────────────────────────────────────────

const double _kPanelWidth = 260.0;

// ── Dropdown items — built once at compile time ───────────────────────────────

const _kPincodeItems = <DropdownMenuItem<int>>[
  DropdownMenuItem(value: 600001, child: Text('600001 · Park Town')),
  DropdownMenuItem(value: 600002, child: Text('600002 · Sowcarpet')),
  DropdownMenuItem(value: 600003, child: Text('600003 · Royapuram')),
  DropdownMenuItem(value: 600004, child: Text('600004 · Chintadripet')),
  DropdownMenuItem(value: 600005, child: Text('600005 · Royapettah')),
  DropdownMenuItem(value: 600006, child: Text('600006 · Triplicane')),
  DropdownMenuItem(value: 600007, child: Text('600007 · Egmore')),
  DropdownMenuItem(value: 600008, child: Text('600008 · Nungambakkam')),
  DropdownMenuItem(value: 600009, child: Text('600009 · Kilpauk')),
  DropdownMenuItem(value: 600010, child: Text('600010 · Aminjikarai')),
  DropdownMenuItem(value: 600011, child: Text('600011 · Perambur')),
  DropdownMenuItem(value: 600012, child: Text('600012 · Ashok Nagar')),
  DropdownMenuItem(value: 600013, child: Text('600013 · Tiruvottiyur')),
  DropdownMenuItem(value: 600015, child: Text('600015 · Pattabiram')),
  DropdownMenuItem(value: 600017, child: Text('600017 · T. Nagar')),
  DropdownMenuItem(value: 600018, child: Text('600018 · Abiramapuram')),
  DropdownMenuItem(value: 600019, child: Text('600019 · Vyasarpadi')),
  DropdownMenuItem(value: 600020, child: Text('600020 · Saidapet')),
  DropdownMenuItem(value: 600024, child: Text('600024 · Pallavaram')),
  DropdownMenuItem(value: 600028, child: Text('600028 · Adyar')),
  DropdownMenuItem(value: 600029, child: Text('600029 · Besant Nagar')),
  DropdownMenuItem(value: 600032, child: Text('600032 · Alwarpet')),
  DropdownMenuItem(value: 600033, child: Text('600033 · Valasaravakkam')),
  DropdownMenuItem(value: 600034, child: Text('600034 · Anna Nagar West')),
  DropdownMenuItem(value: 600035, child: Text('600035 · Anna Nagar East')),
  DropdownMenuItem(value: 600036, child: Text('600036 · Arumbakkam')),
  DropdownMenuItem(value: 600040, child: Text('600040 · Nanganallur')),
  DropdownMenuItem(value: 600042, child: Text('600042 · Velachery')),
  DropdownMenuItem(value: 600044, child: Text('600044 · Perungudi')),
  DropdownMenuItem(value: 600045, child: Text('600045 · Thoraipakkam')),
  DropdownMenuItem(value: 600050, child: Text('600050 · Mogappair')),
  DropdownMenuItem(value: 600053, child: Text('600053 · Villivakkam')),
  DropdownMenuItem(value: 600056, child: Text('600056 · Kolathur')),
  DropdownMenuItem(value: 600058, child: Text('600058 · Royapuram')),
  DropdownMenuItem(value: 600061, child: Text('600061 · Mugalivakkam')),
  DropdownMenuItem(value: 600064, child: Text('600064 · Medavakkam')),
  DropdownMenuItem(value: 600078, child: Text('600078 · Ambattur')),
  DropdownMenuItem(value: 600081, child: Text('600081 · Manali')),
  DropdownMenuItem(value: 600082, child: Text('600082 · Puzhal')),
  DropdownMenuItem(value: 600083, child: Text('600083 · Madhavaram')),
  DropdownMenuItem(value: 600090, child: Text('600090 · Velachery')),
  DropdownMenuItem(value: 600096, child: Text('600096 · OMR')),
  DropdownMenuItem(value: 600099, child: Text('600099 · Kundrathur')),
  DropdownMenuItem(value: 600118, child: Text('600118 · Perumbakkam')),
];

// ── Overlay ───────────────────────────────────────────────────────────────────

/// Wraps any screen. Renders a persistent teal pull-tab on the right edge
/// and a slide-in Judge Mode panel.
/// No BackdropFilter — avoids blur/compositing errors.
class JudgeModeOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const JudgeModeOverlay({super.key, required this.child});

  @override
  ConsumerState<JudgeModeOverlay> createState() => _JudgeModeOverlayState();
}

class _JudgeModeOverlayState extends ConsumerState<JudgeModeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(judgePanelOpenProvider);
    final activePin = ref.watch(judgePincodeProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── App content ────────────────────────────────────────────────
        widget.child,

        // ── Scrim — tap outside to close ───────────────────────────────
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(judgePanelOpenProvider.notifier).state = false,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

        // ── SIMULATION MODE badge — shown when a pincode is active ─────
        if (activePin != null)
          Positioned(
            right: isOpen ? _kPanelWidth + 6 : 28,
            top: topPad + 8,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentBright.withValues(alpha: 0.12),
                  border: Border.all(
                      color: AppColors.accentBright.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'SIMULATION MODE',
                  style: AppText.labelSmallCaps.copyWith(
                    color: AppColors.accentBright,
                    fontSize: 8,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

        // ── Pull-tab ───────────────────────────────────────────────────
        Positioned(
          right: isOpen ? _kPanelWidth : 0,
          top: topPad,
          bottom: 0,
          child: Center(
            child: Tooltip(
              message: 'Drag to simulate pincode',
              child: GestureDetector(
                onTap: () =>
                    ref.read(judgePanelOpenProvider.notifier).state = !isOpen,
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx < -4) {
                    ref.read(judgePanelOpenProvider.notifier).state = true;
                  } else if (details.delta.dx > 4) {
                    ref.read(judgePanelOpenProvider.notifier).state = false;
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) =>
                      Opacity(opacity: _pulseAnim.value, child: child),
                  child: Container(
                    width: 22,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.accentBright,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusMd),
                        bottomLeft: Radius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.drag_handle,
                          color: AppColors.accentDark,
                          size: 13,
                        ),
                        const SizedBox(height: 5),
                        RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            'JM',
                            style: AppText.labelSmallCaps.copyWith(
                              color: AppColors.accentDark,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Slide-in panel ─────────────────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          right: isOpen ? 0 : -_kPanelWidth,
          top: 0,
          bottom: 0,
          width: _kPanelWidth,
          child: const _JudgePanel(),
        ),
      ],
    );
  }
}

// ── Panel ─────────────────────────────────────────────────────────────────────

class _JudgePanel extends ConsumerStatefulWidget {
  const _JudgePanel();

  @override
  ConsumerState<_JudgePanel> createState() => _JudgePanelState();
}

class _JudgePanelState extends ConsumerState<_JudgePanel> {
  // Default to T. Nagar for judge mode demos; user can change via dropdown
  int? _selectedPincode = 600017;
  bool _isSimulating = false;

  Future<void> _simulate(BuildContext context) async {
    // ── Step 1: Validate ────────────────────────────────────────────────
    if (_selectedPincode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pincode.'),
          backgroundColor: Color(0xFF93000A),
        ),
      );
      return;
    }

    final pincode = _selectedPincode!;
    final hour = ref.read(judgeHourProvider);

    // Read current lat/lon from sentinel state (fallback if pincode has no coords)
    final sentinelState = ref.read(sentinelControllerProvider);
    final lat = sentinelState.latitude;
    final lng = sentinelState.longitude;

    // Build the Judge Mode request — forJudge uses pincode coords when available
    final request = RiskPredictionRequest.forJudge(lat, lng, pincode, hour);

    // ── Step 2: Close panel ─────────────────────────────────────────────
    ref.read(judgePanelOpenProvider.notifier).state = false;

    // ── Step 3: Reset intelligence state so the analyzing screen starts fresh
    ref.read(intelligenceControllerProvider.notifier).reset();

    // ── Step 4: Navigate to the analyzing screen ────────────────────────
    if (!context.mounted) return;
    GoRouter.of(context).push('/intelligence');

    // ── Step 5: Call the backend with the full Judge Mode request ────────
    setState(() => _isSimulating = true);
    try {
      await ref
          .read(intelligenceControllerProvider.notifier)
          .scanWithRequest(request);

      // Sync the judge-mode pincode into sentinel state so the rest of the
      // system (SOS flow, police app, dashboard) sees the selected pincode.
      ref.read(sentinelControllerProvider.notifier).overridePincode(pincode);

      // Also refresh the sentinel home screen score
      ref.read(sentinelControllerProvider.notifier).loadRiskScore();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Simulation failed. Check connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = ref.watch(judgeHourProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {},
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: _kPanelWidth,
            constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.97),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
              ),
              border: const Border(
                left: BorderSide(color: AppColors.accentBright, width: 2),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Text(
                      'JUDGE MODE',
                      style: AppText.labelSmallCaps.copyWith(
                        color: AppColors.accentBright,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Divider(color: AppColors.ghostBorder, height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // ── HOUR label + current value ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HOUR',
                          style: AppText.labelSmallCaps
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBright,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // ── Hour slider ────────────────────────────────────
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.accentBright,
                        inactiveTrackColor: AppColors.surfaceHigh,
                        thumbColor: AppColors.accentBright,
                        overlayColor:
                            AppColors.accentBright.withValues(alpha: 0.15),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: hour.toDouble(),
                        min: 0,
                        max: 23,
                        divisions: 23,
                        onChanged: (v) =>
                            ref.read(judgeHourProvider.notifier).state =
                                v.round(),
                      ),
                    ),

                    // Tick labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['0', '6', '12', '18', '23']
                          .map((t) => Text(
                                t,
                                style: AppText.labelSmallCaps
                                    .copyWith(fontSize: 9),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Pincode dropdown ───────────────────────────────
                    DropdownButtonFormField<int>(
                      initialValue: _selectedPincode,
                      dropdownColor: const Color(0xFF0D1B2A),
                      iconEnabledColor: AppColors.accentBright,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        labelText: 'SELECT PINCODE',
                        labelStyle: GoogleFonts.inter(
                          color: AppColors.accentBright.withValues(alpha: 0.7),
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: BorderSide(
                            color:
                                AppColors.accentBright.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: const BorderSide(
                            color: AppColors.accentBright,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      hint: Text(
                        'SELECT PINCODE · AREA',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 320,
                      items: _kPincodeItems,
                      onChanged: (value) {
                        setState(() => _selectedPincode = value);
                        // Sync to provider so score_screen can show the banner
                        ref.read(judgePincodeProvider.notifier).state = value;
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── SIMULATE button ────────────────────────────────
                    RkButton(
                      label: _isSimulating ? 'SIMULATING...' : 'SIMULATE',
                      isLoading: _isSimulating,
                      onPressed:
                          _isSimulating ? null : () => _simulate(context),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Developer simulation tool for testing geo-fenced activity triggers.',
                      style: AppText.labelSmallCaps.copyWith(
                        fontSize: 9,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

/// Rakshak Pulse — Stitch spec
/// Rhythmic opacity animation: 1.0 → 0.6 on the teal accent.
/// Linear curve only — no bounce, no spring.
class RkPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;

  const RkPulse({
    super.key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<RkPulse> createState() => _RkPulseState();
}

class _RkPulseState extends State<RkPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _opacity = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
      child: widget.child,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_spacing.dart';

/// Rakshak Status Chip — Stitch spec
/// Rectangular, radius 2px.
/// Subtle bg: 10% opacity of status color.
/// High-contrast text. No icon circles.
class RkStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const RkStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm / 2), // 2px
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum RkButtonVariant { primary, secondary, danger }

/// Rakshak Button — Stitch spec
/// Primary : bg #46F1CF, text #00382E, radius 4px
/// Secondary: bg surfaceHighest, text white, radius 4px
/// Danger   : bg #93000A, text white, radius 4px
/// Press    : scale 0.98 — linear curve, no bounce
class RkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary; // legacy compat
  final RkButtonVariant variant;
  final IconData? icon;
  final double? height;

  const RkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.variant = RkButtonVariant.primary,
    this.icon,
    this.height,
  });

  @override
  State<RkButton> createState() => _RkButtonState();
}

class _RkButtonState extends State<RkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  RkButtonVariant get _effectiveVariant =>
      widget.isSecondary ? RkButtonVariant.secondary : widget.variant;

  Color get _bgColor {
    switch (_effectiveVariant) {
      case RkButtonVariant.primary:
        return AppColors.accentBright;
      case RkButtonVariant.secondary:
        return AppColors.surfaceHighest;
      case RkButtonVariant.danger:
        return AppColors.alertRed;
    }
  }

  Color get _fgColor {
    switch (_effectiveVariant) {
      case RkButtonVariant.primary:
        return const Color(0xFF00382E);
      case RkButtonVariant.secondary:
      case RkButtonVariant.danger:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => _pressCtrl.forward() : null,
      onTapUp: enabled
          ? (_) {
              _pressCtrl.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.linear,
          height: widget.height ?? AppSpacing.buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled ? _bgColor : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_fgColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: enabled ? _fgColor : AppColors.textTertiary),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: enabled ? _fgColor : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Rakshak Scaffold — persistent bottom nav bar on all shell screens.
/// Judge Mode pull-tab is injected by JudgeModeOverlay at the router level.
///
/// Notch padding on web is handled globally in main.dart via MediaQuery,
/// so SafeArea on every screen automatically clears the CSS notch.
class RkScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;
  final String languageCode;

  const RkScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // SafeArea applied here (top only) clears the Dynamic Island / notch for
      // every shell screen. bottom: false because the bottom nav bar carries its
      // own SafeArea(top: false) and Scaffold already insets the body above it.
      body: SafeArea(
        top: true,
        bottom: false,
        child: body,
      ),
      bottomNavigationBar: _RkBottomNav(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        languageCode: languageCode,
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _RkBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String languageCode;

  const _RkBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.languageCode,
  });

  static const _items = [
    _NavItem(
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield,
      labelEn: 'SENTINEL',
      labelTa: 'காவலன்',
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      labelEn: 'ALERTS',
      labelTa: 'எச்சரிக்கை',
    ),
    _NavItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      labelEn: 'MAP',
      labelTa: 'வரைபடம்',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelEn: 'PROFILE',
      labelTa: 'பயனர்',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.ghostBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Teal top-border indicator on active tab
                      if (active)
                        Positioned(
                          top: 0,
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.accentBright,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      // Icon + label
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              active ? item.activeIcon : item.icon,
                              size: AppSpacing.iconSize,
                              color: active
                                  ? AppColors.accentBright
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              languageCode == 'ta'
                                  ? item.labelTa
                                  : item.labelEn,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: active
                                    ? AppColors.accentBright
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelEn;
  final String labelTa;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelEn,
    required this.labelTa,
  });
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/sentinel/presentation/sentinel_screen.dart';
import '../../features/sentinel/presentation/night_watch_overlay.dart';
import '../../features/alerts/presentation/alerts_stub_screen.dart';
import '../../features/map/presentation/map_stub_screen.dart';
import '../../features/user_space/presentation/user_space_screen.dart';
import '../../features/intelligence/presentation/intelligence_screen.dart';
import '../../features/intelligence/presentation/score_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../widgets/rk_scaffold.dart';
import '../widgets/judge_mode_overlay.dart';
import '../../core/providers/settings_provider.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Login — no shell, no Judge Mode
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),

    // Shell — bottom nav + Judge Mode overlay
    ShellRoute(
      builder: (context, state, child) =>
          _ShellWithJudgeMode(child: child, routerState: state),
      routes: [
        GoRoute(
          path: '/sentinel',
          builder: (context, state) => const SentinelScreen(),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const AlertsStubScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapStubScreen(),
        ),
        GoRoute(
          path: '/user-space',
          builder: (context, state) => const UserSpaceScreen(),
        ),
      ],
    ),

    // Fullscreen routes — Judge Mode overlay, no bottom nav
    GoRoute(
      path: '/intelligence',
      builder: (context, state) => JudgeModeOverlay(
        child: const IntelligenceScreen(),
      ),
    ),
    GoRoute(
      path: '/score',
      builder: (context, state) => JudgeModeOverlay(
        child: const ScoreScreen(),
      ),
    ),
    GoRoute(
      path: '/night-watch',
      builder: (context, state) => const Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: true,
          bottom: false,
          child: NightWatchOverlay(),
        ),
      ),
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const SosScreen(),
    ),
  ],
);

// ── Shell wrapper ─────────────────────────────────────────────────────────────

class _ShellWithJudgeMode extends ConsumerWidget {
  final Widget child;
  final GoRouterState routerState;

  const _ShellWithJudgeMode(
      {required this.child, required this.routerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).languageCode;
    final currentTab = _tabIndex(routerState.uri.toString());

    return JudgeModeOverlay(
      child: RkScaffold(
        body: child,
        currentIndex: currentTab,
        languageCode: lang,
        onTabChanged: (i) => GoRouter.of(context).go(_tabRoute(i)),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _tabIndex(String path) {
  if (path.contains('/alerts')) return 1;
  if (path.contains('/map')) return 2;
  if (path.contains('/user-space')) return 3;
  return 0;
}

String _tabRoute(int i) {
  switch (i) {
    case 1:
      return '/alerts';
    case 2:
      return '/map';
    case 3:
      return '/user-space';
    default:
      return '/sentinel';
  }
}
const String apiBase = 'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com';

const String sosLive         = '$apiBase/sos/live';
const String sosDispatch     = '$apiBase/sos/dispatch';
const String sosResolve      = '$apiBase/sos/resolve';
const String policeSosActive = '$apiBase/police/sos/active';
const String policeSosAccept = '$apiBase/police/sos';   // PATCH /police/sos/{id}/status
const String patrolsList     = '$apiBase/patrols';
const String patrolStatus    = '$apiBase/patrols';
const String scoreRefresh    = '$apiBase/score/refresh';
const String patrolOptimizer = '$apiBase/patrol/optimize';

const String citizensActive = '$apiBase/police/citizens/active';
const String policeRoute    = '$apiBase/police/route';
const String sosActive      = '$apiBase/police/sos/active';
const String sosCancelled   = '$apiBase/sos/cancelled';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/risk_prediction_request.dart';
import '../../../core/models/risk_score.dart';
import '../../../core/models/risk_score_response.dart';
import '../domain/intelligence_service.dart';

class IntelligenceRepository implements IntelligenceService {
  /// Call POST /predict with a fully-built request
  Future<RiskScoreResponse> predict(RiskPredictionRequest request) async {
    final response = await http
        .post(
          Uri.parse(ApiEndpoints.predict),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return RiskScoreResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw HttpException('Prediction failed (${response.statusCode})');
  }

  @override
  Future<RiskScore> scanLocation(double latitude, double longitude) async {
    final request = RiskPredictionRequest.fromGps(
      latitude,
      longitude,
      0, // GPS-derived lookup; no hardcoded default
    );

    final apiResponse = await predict(request);
    return apiResponse.toRiskScore();
  }

  /// Scan with explicit pincode (used by Judge Mode and sentinel-aware flows)
  Future<RiskScore> scanLocationWithPincode(
    double latitude,
    double longitude,
    int pincode,
  ) async {
    final request = RiskPredictionRequest.fromGps(latitude, longitude, pincode);
    final apiResponse = await predict(request);
    return apiResponse.toRiskScore();
  }

  /// Scan with a fully custom request (Judge Mode hour override)
  Future<RiskScore> scanWithRequest(RiskPredictionRequest request) async {
    final apiResponse = await predict(request);
    return apiResponse.toRiskScore();
  }

  @override
  Future<List<RiskScore>> getRiskHistory() async {
    return const [];
  }
}
import '../../../core/models/risk_score.dart';

/// Intelligence service interface
abstract class IntelligenceService {
  /// Scan location for risk assessment
  Future<RiskScore> scanLocation(double latitude, double longitude);

  /// Get risk history
  Future<List<RiskScore>> getRiskHistory();
}
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/risk_score.dart';
import '../../../core/models/risk_prediction_request.dart';
import '../data/intelligence_repository.dart';

/// Intelligence state
enum ScanStatus {
  idle,
  scanning,
  complete,
  error,
}

class IntelligenceState {
  final ScanStatus status;
  final RiskScore? result;
  final String? error;
  final double progress; // 0.0 to 1.0

  const IntelligenceState({
    this.status = ScanStatus.idle,
    this.result,
    this.error,
    this.progress = 0.0,
  });

  IntelligenceState copyWith({
    ScanStatus? status,
    RiskScore? result,
    String? error,
    double? progress,
  }) {
    return IntelligenceState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error,
      progress: progress ?? this.progress,
    );
  }
}

/// Intelligence controller
class IntelligenceController extends StateNotifier<IntelligenceState> {
  final IntelligenceRepository _repo;

  IntelligenceController(this._repo) : super(const IntelligenceState());

  /// Standard scan — uses GPS lat/lon + default pincode
  Future<void> scanLocation(double latitude, double longitude,
      {String lang = 'en', int pincode = 0}) async {
    state = state.copyWith(status: ScanStatus.scanning, progress: 0.0);

    try {
      // Animate progress while awaiting the real HTTP call
      var progressTimer = 0.0;
      final ticker =
          Stream.periodic(const Duration(milliseconds: 300), (i) => i)
              .take(9)
              .listen((_) {
        progressTimer = (progressTimer + 0.1).clamp(0.0, 0.9);
        state = state.copyWith(progress: progressTimer);
      });

      final result =
          await _repo.scanLocationWithPincode(latitude, longitude, pincode);
      await ticker.cancel();

      state = state.copyWith(
        status: ScanStatus.complete,
        result: result,
        progress: 1.0,
      );
    } on TimeoutException {
      state = state.copyWith(
        status: ScanStatus.error,
        error: AppStrings.get(AppStrings.timeoutError, lang),
      );
    } on SocketException {
      state = state.copyWith(
        status: ScanStatus.error,
        error: AppStrings.get(AppStrings.networkError, lang),
      );
    } on HttpException {
      state = state.copyWith(
        status: ScanStatus.error,
        error: AppStrings.get(AppStrings.serverError, lang),
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        error: AppStrings.get(AppStrings.networkError, lang),
      );
    }
  }

  /// Judge Mode scan — uses a fully custom request with hour override
  Future<void> scanWithRequest(RiskPredictionRequest request,
      {String lang = 'en'}) async {
    state = state.copyWith(status: ScanStatus.scanning, progress: 0.0);

    try {
      var progressTimer = 0.0;
      final ticker =
          Stream.periodic(const Duration(milliseconds: 300), (i) => i)
              .take(9)
              .listen((_) {
        progressTimer = (progressTimer + 0.1).clamp(0.0, 0.9);
        state = state.copyWith(progress: progressTimer);
      });

      final result = await _repo.scanWithRequest(request);
      await ticker.cancel();

      state = state.copyWith(
        status: ScanStatus.complete,
        result: result,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        error: AppStrings.get(AppStrings.networkError, lang),
      );
    }
  }

  void reset() {
    state = const IntelligenceState();
  }
}

/// Intelligence repository provider (concrete type)
final intelligenceRepositoryProvider = Provider<IntelligenceRepository>((ref) {
  return IntelligenceRepository();
});

/// Intelligence controller provider
final intelligenceControllerProvider =
    StateNotifierProvider<IntelligenceController, IntelligenceState>((ref) {
  return IntelligenceController(ref.watch(intelligenceRepositoryProvider));
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_status_chip.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/constants/pincode_map.dart';
import '../../../core/widgets/judge_mode_overlay.dart';
import 'intelligence_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Score Screen — Final intelligence result
// Shows risk score, alert prompt, AI analysis card.
// Shows Judge Mode context banner when result came from simulation.
// ─────────────────────────────────────────────────────────────────────────────

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).languageCode;
    final state = ref.watch(intelligenceControllerProvider);

    // Judge Mode context
    final judgeHour = ref.watch(judgeHourProvider);
    final judgePincode = ref.watch(judgePincodeProvider) ?? 0;
    final isJudgeMode = judgePincode >= 600001;

    final score = state.result?.score ?? 0;
    final isCritical = score >= 75;
    final scoreColor = isCritical ? AppColors.riskHigh : AppColors.riskMedium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  RkLabel.small('RAKSHAK', color: AppColors.textPrimary),
                ],
              ),
            ),

            // ── Judge Mode context banner ─────────────────────────────
            if (isJudgeMode)
              _JudgeBanner(pincode: judgePincode, hour: judgeHour),

            // ── Scrollable content ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // ── Score hero ──────────────────────────────────────
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            score > 0 ? score.toString() : '--',
                            style: GoogleFonts.inter(
                              fontSize: 120,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              color: scoreColor,
                              letterSpacing: -0.02 * 120,
                            ),
                          ),
                          if (isCritical)
                            Positioned(
                              top: 8,
                              right: -8,
                              child: Transform.rotate(
                                angle: -0.35,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.riskHigh,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    'HIGH RISK',
                                    style: AppText.labelSmallCaps.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── CRITICAL INTELLIGENCE badge ─────────────────────
                    if (isCritical)
                      Center(
                        child: RkStatusChip(
                          label: '⚠ CRITICAL INTELLIGENCE',
                          color: AppColors.riskHigh,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Anomaly text ────────────────────────────────────
                    Center(
                      child: Text(
                        lang == 'ta'
                            ? 'தற்போதைய சுற்றுப்புறத்தில் அசாதாரண வடிவம் கண்டறியப்பட்டது.'
                            : 'Anomalous pattern detected in current vicinity.',
                        style: AppText.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Alert emergency services card ───────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'ta'
                                ? 'அவசர சேவைகளை எச்சரிக்கவா?'
                                : 'Alert emergency services?',
                            style: AppText.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'அவசர சேவைகளை அழைக்கவா?',
                            style: AppText.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── YES button ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => context.push('/sos'),
                      child: Container(
                        height: AppSpacing.buttonHeight,
                        decoration: BoxDecoration(
                          color: AppColors.riskHigh,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Center(
                          child: Text(
                            '✦  YES',
                            style: AppText.button
                                .copyWith(color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── NO button ───────────────────────────────────────
                    RkButton(
                      label: 'NO',
                      variant: RkButtonVariant.secondary,
                      onPressed: () => context.pop(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── AI System Analysis card ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: const Border(
                          left: BorderSide(
                              color: AppColors.accentBright, width: 2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                            ),
                            child: const Icon(Icons.psychology_outlined,
                                color: AppColors.accentBright, size: 18),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: RkLabel.small('SYSTEM ANALYSIS',
                                          color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppColors.riskHigh,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: RkLabel.small('LIVE MONITORING',
                                          color: AppColors.riskHigh),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  state.result != null
                                      ? state.result!.factors.join(' · ')
                                      : 'AI Sentinel has cross-referenced local incident reports with current biometric spikes. Confidence level: 94%.',
                                  style: AppText.bodyMedium.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Judge Mode context banner ─────────────────────────────────────────────────

class _JudgeBanner extends StatelessWidget {
  final int pincode;
  final int hour;

  const _JudgeBanner({required this.pincode, required this.hour});

  @override
  Widget build(BuildContext context) {
    final areaName = pincodeToAreaName[pincode] ?? 'Chennai';
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          left: BorderSide(color: AppColors.accentBright, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on,
              color: AppColors.accentBright, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$pincode · $areaName',
              style: AppText.labelSmallCaps.copyWith(
                  color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            ' · ',
            style: AppText.labelSmallCaps
                .copyWith(color: AppColors.textTertiary),
          ),
          const Icon(Icons.access_time,
              color: AppColors.accentBright, size: 14),
          const SizedBox(width: 4),
          Text(
            timeStr,
            style: AppText.labelSmallCaps.copyWith(
                color: AppColors.accentBright),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/providers/settings_provider.dart';
import 'intelligence_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Intelligence Screen — Loading / Analyzing
// Arc sweeps to riskIndex, scan rows appear sequentially, chips fade in.
// Minimum display time: 2400ms (Future.wait pattern).
// ─────────────────────────────────────────────────────────────────────────────

class IntelligenceScreen extends ConsumerStatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  ConsumerState<IntelligenceScreen> createState() =>
      _IntelligenceScreenState();
}

class _IntelligenceScreenState extends ConsumerState<IntelligenceScreen>
    with TickerProviderStateMixin {
  // Arc animation
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;

  // Percentage counter
  int _displayedPercent = 0;
  Timer? _counterTimer;

  // Scan row visibility
  final List<bool> _rowVisible = [false, false, false];
  final List<bool> _rowDone = [false, false, false];
  bool _chipsVisible = false;

  bool _apiDone = false;

  @override
  void initState() {
    super.initState();

    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic);

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Minimum display time + API call run in parallel
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 2400));

    // Row 1 appears at 400ms, completes at 1000ms
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _rowVisible[0] = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _rowDone[0] = true);

    // Row 2 appears at 900ms from start (100ms after row 1 appears)
    // We're at 1000ms now, row 2 should have appeared at 900ms.
    // Show it immediately (it's already past 900ms).
    setState(() => _rowVisible[1] = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _rowDone[1] = true);

    // Row 3 appears at 1500ms from start — we're at ~1600ms, show immediately
    setState(() => _rowVisible[2] = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _rowDone[2] = true;
      _chipsVisible = true;
    });

    // Wait for both minimum time and API
    await minDelay;

    // Wait until API is done (controller state is complete/error)
    while (!_apiDone && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    // Arc always sweeps 0→100% (analysis progress, not risk score)
    _arcCtrl.forward();
    _startCounter(100);

    // Wait for arc animation to finish
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    context.pushReplacement('/score');
  }

  void _startCounter(int target) {
    _counterTimer?.cancel();
    final steps = 36; // ~50ms per step over 1800ms
    int step = 0;
    _counterTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      step++;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _displayedPercent = (target * step / steps).round().clamp(0, target);
      });
      if (step >= steps) t.cancel();
    });
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _counterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;
    final state = ref.watch(intelligenceControllerProvider);

    // Mark API done when controller reaches complete/error
    if ((state.status == ScanStatus.complete ||
            state.status == ScanStatus.error) &&
        !_apiDone) {
      _apiDone = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  RkLabel.small('SENTINEL INTELLIGENCE ACTIVE',
                      color: AppColors.accentBright),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Arc progress (220px) ──────────────────────────────────
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _arcAnim,
                  builder: (_, __) => CustomPaint(
                    painter: _ArcPainter(progress: _arcAnim.value),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_displayedPercent%',
                            style: AppText.displayLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          RkLabel.small('ANALYZING',
                              color: AppColors.accentBright),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Scan rows ─────────────────────────────────────────────
              ..._buildScanRows(lang),

              const SizedBox(height: AppSpacing.lg),

              // ── Chips (fade in after all rows done) ───────────────────
              AnimatedOpacity(
                opacity: _chipsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_apiDone && state.result != null
                                  ? _riskColor(state.result!.score)
                                  : AppColors.textSecondary)
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: _apiDone && state.result != null
                                ? _riskColor(state.result!.score)
                                : AppColors.textSecondary,
                          ),
                        ),
                        child: Text(
                          _apiDone && state.result != null
                              ? 'THREAT: ${state.result!.level.name.toUpperCase()}'
                              : 'THREAT LEVEL: —',
                          style: AppText.labelSmallCaps.copyWith(
                            color: _apiDone && state.result != null
                                ? _riskColor(state.result!.score)
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentBright.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.accentBright),
                        ),
                        child: Text(
                          'ENCRYPTION: AES-256',
                          style: AppText.labelSmallCaps
                              .copyWith(color: AppColors.accentBright),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── System integrity bar ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RkLabel.small('SYSTEM INTEGRITY',
                            color: AppColors.textSecondary),
                        RkLabel.small(
                          _apiDone ? 'COMPLETE' : 'PROCESSING...',
                          color: AppColors.accentBright,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedBuilder(
                      animation: _arcAnim,
                      builder: (_, __) => ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: LinearProgressIndicator(
                          value: _arcAnim.value,
                          minHeight: 4,
                          backgroundColor: AppColors.surfaceHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentBright),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScanRows(String lang) {
    const labels = [
      ('Scanning active location...', 'இருப்பிடத்தை ஸ்கேன் செய்கிறது...'),
      ('Analyzing threat patterns...', 'அச்சுறுத்தல் வடிவங்களை பகுப்பாய்வு செய்கிறது...'),
      ('Calculating Police ETA...', 'காவல் ரோந்து ETA கணக்கிடுகிறது...'),
    ];

    return List.generate(3, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AnimatedOpacity(
          opacity: _rowVisible[i] ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: _ScanRow(
            labelEn: labels[i].$1,
            labelTa: labels[i].$2,
            isDone: _rowDone[i],
            lang: lang,
          ),
        ),
      );
    });
  }

  Color _riskColor(int score) {
    if (score >= 75) return AppColors.riskHigh;
    if (score >= 50) return AppColors.riskMedium;
    return AppColors.riskLow;
  }
}

// ── Scan row ──────────────────────────────────────────────────────────────────

class _ScanRow extends StatelessWidget {
  final String labelEn;
  final String labelTa;
  final bool isDone;
  final String lang;

  const _ScanRow({
    required this.labelEn,
    required this.labelTa,
    required this.isDone,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isDone
            ? const Border(
                left: BorderSide(color: AppColors.accentBright, width: 2))
            : null,
      ),
      child: Row(
        children: [
          // Dot — pulsing while pending, solid when done
          _ScanDot(isDone: isDone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              lang == 'ta' ? labelTa : labelEn,
              style: AppText.bodyMedium.copyWith(
                color: isDone
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          if (isDone)
            Text(
              'OK',
              style: AppText.labelSmallCaps.copyWith(
                color: AppColors.accentBright,
                letterSpacing: 1,
              ),
            )
          else
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: AppColors.accentBright,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Animated dot ──────────────────────────────────────────────────────────────

class _ScanDot extends StatefulWidget {
  final bool isDone;
  const _ScanDot({required this.isDone});

  @override
  State<_ScanDot> createState() => _ScanDotState();
}

class _ScanDotState extends State<_ScanDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDone) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.accentBright,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.accentBright,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Arc painter ───────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Track — surfaceContainer
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Arc — teal progress
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
import '../domain/auth_service.dart';

/// Stub implementation of AuthService
class AuthRepository implements AuthService {
  @override
  Future<bool> sendOtp(String phoneNumber) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    // Always succeed for stub
    return true;
  }

  @override
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    // Accept any 6-digit OTP for stub
    return otp.length == 6;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> isAuthenticated() async {
    // For stub, always return false (user needs to login)
    return false;
  }
}
/// Authentication service interface
abstract class AuthService {
  /// Send OTP to phone number
  Future<bool> sendOtp(String phoneNumber);

  /// Verify OTP
  Future<bool> verifyOtp(String phoneNumber, String otp);

  /// Logout
  Future<void> logout();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    // TODO: wire to authControllerProvider.sendOtp(_phoneCtrl.text)
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) context.go('/sentinel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dot-grid background
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 375),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Logo ──────────────────────────────────────────
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                              color: AppColors.accentBright.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: const Icon(Icons.shield,
                            color: AppColors.accentBright, size: 28),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── App name ──────────────────────────────────────
                      Text(
                        'RAKSHAK',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentBright,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // ── Sentinel active indicator ─────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RkPulse(
                            color: AppColors.accentBright,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accentBright,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          RkLabel.small(
                            'SENTINEL INTELLIGENCE ACTIVE',
                            color: AppColors.accentBright,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Phone input card ──────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RkLabel.small('PHONE IDENTIFIER',
                                color: AppColors.textSecondary),
                            const SizedBox(height: AppSpacing.xs),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: 3,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                prefixText: '+91  ',
                                prefixStyle: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                                hintText: '000 000 0000',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: AppColors.textTertiary,
                                  letterSpacing: 3,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            // Ghost border bottom
                            Container(
                              height: 1,
                              color: _phoneCtrl.text.isNotEmpty
                                  ? AppColors.accentBright
                                  : AppColors.ghostBorder,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Security notice ───────────────────────────────
                      Text(
                        'Access requires encrypted two-factor verification. '
                        'A secure handshake signal will be transmitted to your registered device.',
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Login button ──────────────────────────────────
                      RkButton(
                        label: 'SECURE LOGIN  ›',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // ── Footer links ──────────────────────────────────
                      RkLabel.small('PRIVACY POLICY',
                          color: AppColors.textSecondary),
                      const SizedBox(height: AppSpacing.sm),
                      RkLabel.small('SYSTEM TECHNICAL SUPPORT',
                          color: AppColors.textTertiary),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Version ───────────────────────────────────────
                      RkLabel.small('RAKSHAK SENTINEL V1.0',
                          color: AppColors.textTertiary),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_service.dart';

/// Auth state
enum AuthStatus {
  initial,
  sendingOtp,
  otpSent,
  verifying,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? phoneNumber;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.phoneNumber,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? phoneNumber,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

/// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      phoneNumber: phoneNumber,
    );

    try {
      final success = await _authService.sendOtp(phoneNumber);
      if (success) {
        state = state.copyWith(status: AuthStatus.otpSent);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: 'Failed to send OTP',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.phoneNumber == null) return;

    state = state.copyWith(status: AuthStatus.verifying);

    try {
      final success = await _authService.verifyOtp(state.phoneNumber!, otp);
      if (success) {
        state = state.copyWith(status: AuthStatus.authenticated);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: 'Invalid OTP',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const AuthState();
  }
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthRepository();
});

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/risk_prediction_request.dart';
import '../../../core/models/risk_score.dart';
import '../../../core/models/risk_score_response.dart';
import '../domain/sentinel_service.dart';

/// Live implementation of SentinelService — calls POST /predict
class SentinelRepository implements SentinelService {
  bool _nightWatchActive = false;

  // Current location state — set by the controller after GPS acquisition
  double _lat = 13.0827;
  double _lng = 80.2707;
  int _pincode = 0;
  String _areaName = '';

  // ── Getters for location state ──────────────────────────────────────────
  double get latitude => _lat;
  double get longitude => _lng;
  int get pincode => _pincode;
  String get areaName => _areaName;

  /// Update the cached location (called by controller after GPS/geocode)
  void updateLocation({
    required double lat,
    required double lng,
    required int pincode,
    required String areaName,
  }) {
    _lat = lat;
    _lng = lng;
    _pincode = pincode;
    _areaName = areaName;
  }

  /// Call POST /predict with the current location
  Future<RiskScoreResponse> predict(RiskPredictionRequest request) async {
    final response = await http
        .post(
          Uri.parse(ApiEndpoints.predict),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return RiskScoreResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Prediction failed: ${response.statusCode}');
  }

  @override
  Future<RiskScore> getCurrentRiskScore() async {
    final request = RiskPredictionRequest.fromGps(_lat, _lng, _pincode);
    final apiResponse = await predict(request);
    return apiResponse.toRiskScore(location: '$_pincode · $_areaName');
  }

  @override
  Future<bool> activateNightWatch() async {
    _nightWatchActive = true;
    return true;
  }

  @override
  Future<bool> deactivateNightWatch() async {
    _nightWatchActive = false;
    return true;
  }

  @override
  Future<bool> isNightWatchActive() async {
    return _nightWatchActive;
  }
}
import '../../../core/models/risk_score.dart';

/// Sentinel service interface
abstract class SentinelService {
  /// Get current risk score for user's location
  Future<RiskScore> getCurrentRiskScore();

  /// Activate night watch mode
  Future<bool> activateNightWatch();

  /// Deactivate night watch mode
  Future<bool> deactivateNightWatch();

  /// Check if night watch is active
  Future<bool> isNightWatchActive();
}
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
// geocoding is not supported on web — imported conditionally at runtime
import 'package:geocoding/geocoding.dart'
    if (dart.library.html) '../../../core/stubs/geocoding_stub.dart';
import '../../../core/models/risk_score.dart';
import '../data/sentinel_repository.dart';

/// Sentinel state — exposed to the UI
class SentinelState {
  final RiskScore? riskScore;
  final bool isLoading;
  final bool nightWatchActive;
  final String? error;
  final double latitude;
  final double longitude;
  final int pincode;
  final String areaName;

  const SentinelState({
    this.riskScore,
    this.isLoading = false,
    this.nightWatchActive = false,
    this.error,
    this.latitude = 13.0827,
    this.longitude = 80.2707,
    this.pincode = 0,
    this.areaName = '',
  });

  SentinelState copyWith({
    RiskScore? riskScore,
    bool? isLoading,
    bool? nightWatchActive,
    String? error,
    double? latitude,
    double? longitude,
    int? pincode,
    String? areaName,
  }) {
    return SentinelState(
      riskScore: riskScore ?? this.riskScore,
      isLoading: isLoading ?? this.isLoading,
      nightWatchActive: nightWatchActive ?? this.nightWatchActive,
      error: error,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pincode: pincode ?? this.pincode,
      areaName: areaName ?? this.areaName,
    );
  }
}

/// Sentinel controller — GPS + live /predict + 60s auto-refresh
class SentinelController extends StateNotifier<SentinelState> {
  final SentinelRepository _repo;
  Timer? _refreshTimer;

  SentinelController(this._repo) : super(const SentinelState()) {
    _init();
  }

  Future<void> _init() async {
    await _acquireLocation();
    await loadRiskScore();
    // Auto-refresh every 60 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => loadRiskScore(),
    );
  }

  /// Acquire GPS + reverse geocode to get pincode
  Future<void> _acquireLocation() async {
    try {
      // Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Fall back to defaults
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      final lat = position.latitude;
      final lng = position.longitude;

      // Reverse geocode to get pincode + area name
      int pincode = 0;
      String areaName = '';
      if (!kIsWeb) {
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng)
              .timeout(const Duration(seconds: 5));
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            pincode = int.tryParse(pm.postalCode ?? '') ?? 0;
            areaName = pm.subLocality?.isNotEmpty == true
                ? pm.subLocality!
                : pm.locality ?? 'Chennai';
          }
        } catch (_) {
          // Geocoding failed — keep defaults
        }
      }

      // Update repository + state
      _repo.updateLocation(
        lat: lat,
        lng: lng,
        pincode: pincode,
        areaName: areaName,
      );

      state = state.copyWith(
        latitude: lat,
        longitude: lng,
        pincode: pincode,
        areaName: areaName,
      );
    } catch (_) {
      // GPS failed — keep defaults, don't crash
    }
  }

  /// Call /predict and update state
  Future<void> loadRiskScore() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final riskScore = await _repo.getCurrentRiskScore();
      state = state.copyWith(
        riskScore: riskScore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Override pincode from Judge Mode — propagates to SOS flow and UI.
  void overridePincode(int pincode) {
    final coords = _pincodeCoords[pincode];
    state = state.copyWith(
      pincode: pincode,
      areaName: _pincodeNames[pincode] ?? 'Chennai',
      latitude:  coords?[0] ?? state.latitude,
      longitude: coords?[1] ?? state.longitude,
    );
    _repo.updateLocation(
      lat:      state.latitude,
      lng:      state.longitude,
      pincode:  pincode,
      areaName: state.areaName,
    );
  }

  // Pincode → [lat, lng] for the 44 Chennai zones used in Judge Mode
  static const Map<int, List<double>> _pincodeCoords = {
    600001: [13.0827, 80.2707], 600002: [13.0878, 80.2785],
    600003: [13.0950, 80.2866], 600004: [13.0732, 80.2609],
    600005: [13.0569, 80.2787], 600006: [13.0715, 80.2740],
    600007: [13.1127, 80.2966], 600008: [13.1186, 80.2487],
    600009: [13.1483, 80.2355], 600010: [13.1675, 80.2617],
    600011: [13.0827, 80.2487], 600012: [13.0950, 80.2193],
    600013: [13.0732, 80.2193], 600015: [13.0339, 80.2707],
    600017: [13.0067, 80.2570], 600018: [13.0521, 80.2193],
    600019: [13.0475, 80.2030], 600020: [13.0521, 80.2118],
    600024: [12.9815, 80.2209], 600028: [12.9995, 80.2666],
    600029: [12.9845, 80.2657], 600032: [13.0350, 80.2323],
    600033: [13.0521, 80.2030], 600034: [13.0339, 80.2193],
    600035: [13.0402, 80.2091], 600036: [13.0883, 80.2105],
    600040: [13.0850, 80.2101], 600042: [13.0883, 80.1762],
    600044: [13.0339, 80.1575], 600045: [13.0237, 80.1762],
    600050: [12.9673, 80.1501], 600053: [12.9515, 80.1438],
    600056: [12.9625, 80.2387], 600058: [13.1127, 80.2966],
    600061: [12.9000, 80.2277], 600064: [12.9240, 80.1958],
    600078: [13.1144, 80.1606], 600081: [13.1675, 80.2617],
    600082: [13.1675, 80.2355], 600083: [13.1483, 80.2355],
    600090: [12.9815, 80.2209], 600096: [12.9625, 80.2387],
    600099: [13.1186, 80.2091], 600118: [12.9065, 80.1958],
  };

  static const Map<int, String> _pincodeNames = {
    600001: 'Park Town',       600002: 'Sowcarpet',
    600003: 'Royapuram',       600004: 'Chintadripet',
    600005: 'Royapettah',      600006: 'Triplicane',
    600007: 'Egmore',          600008: 'Nungambakkam',
    600009: 'Kilpauk',         600010: 'Aminjikarai',
    600011: 'Perambur',        600012: 'Ashok Nagar',
    600013: 'Tiruvottiyur',    600015: 'Pattabiram',
    600017: 'T. Nagar',        600018: 'Abiramapuram',
    600019: 'Vyasarpadi',      600020: 'Saidapet',
    600024: 'Pallavaram',      600028: 'Adyar',
    600029: 'Besant Nagar',    600032: 'Alwarpet',
    600033: 'Valasaravakkam',  600034: 'Anna Nagar West',
    600035: 'Anna Nagar East', 600036: 'Arumbakkam',
    600040: 'Nanganallur',     600042: 'Velachery',
    600044: 'Perungudi',       600045: 'Thoraipakkam',
    600050: 'Mogappair',       600053: 'Villivakkam',
    600056: 'Kolathur',        600058: 'Royapuram',
    600061: 'Mugalivakkam',    600064: 'Medavakkam',
    600078: 'Ambattur',        600081: 'Manali',
    600082: 'Puzhal',          600083: 'Madhavaram',
    600090: 'Velachery',       600096: 'OMR',
    600099: 'Kundrathur',      600118: 'Perumbakkam',
  };

  Future<void> toggleNightWatch() async {
    final isActive = state.nightWatchActive;
    try {
      if (isActive) {
        await _repo.deactivateNightWatch();
        state = state.copyWith(nightWatchActive: false);
      } else {
        await _repo.activateNightWatch();
        state = state.copyWith(nightWatchActive: true);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Sentinel repository provider (concrete type so we can access location)
final sentinelRepositoryProvider = Provider<SentinelRepository>((ref) {
  return SentinelRepository();
});

/// Sentinel controller provider
final sentinelControllerProvider =
    StateNotifierProvider<SentinelController, SentinelState>((ref) {
  return SentinelController(ref.watch(sentinelRepositoryProvider));
});
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_status_chip.dart';
import '../../../core/providers/settings_provider.dart';
import 'sentinel_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Night Watch Overlay — "Help is on the way" full-screen secured state
// ─────────────────────────────────────────────────────────────────────────────

class NightWatchOverlay extends ConsumerStatefulWidget {
  const NightWatchOverlay({super.key});

  @override
  ConsumerState<NightWatchOverlay> createState() => _NightWatchOverlayState();
}

class _NightWatchOverlayState extends ConsumerState<NightWatchOverlay> {
  Timer? _clockTimer;
  Timer? _etaTimer;
  String _clockTime = '';
  int _etaSeconds = 4 * 60 + 30; // 4:30

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_etaSeconds > 0) _etaSeconds--;
      });
    });
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _clockTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  String get _etaDisplay {
    if (_etaSeconds <= 0) return 'ARRIVING';
    final m = _etaSeconds ~/ 60;
    final s = _etaSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. STATUS BAR ─────────────────────────────────────────
              _StatusBar(clockTime: _clockTime),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // ── 2. HERO SECTION ───────────────────────────────
                    Text(
                      lang == 'ta'
                          ? 'உதவி வந்து கொண்டிருக்கிறது.'
                          : 'Help is on the way.',
                      style: AppText.displayLarge.copyWith(
                        fontSize: 48,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your location is secured. Please stay in a well-lit place.',
                      style: AppText.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'உங்கள் இருப்பிடம் பாதுகாப்பானது. வெளிச்சமான இடத்தில் இருக்கவும்.',
                      style: AppText.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 3. ACTIVE ELEMENTS ROW ────────────────────────
                    Row(
                      children: [
                        Expanded(child: _PatrolCard()),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _SignalCard()),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _SentinelCard()),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 4. PATROL ETA CARD ────────────────────────────
                    _EtaCard(
                        etaDisplay: _etaDisplay,
                        isArriving: _etaSeconds <= 0),

                    const SizedBox(height: AppSpacing.md),

                    // ── 5. SIGNAL / ENCRYPTION CHIPS ─────────────────
                    Row(
                      children: const [
                        RkStatusChip(
                          label: 'THREAT LEVEL: HIGH',
                          color: AppColors.riskHigh,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        RkStatusChip(
                          label: 'ENCRYPTION: AES-256',
                          color: AppColors.accentBright,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 6. AI ANALYSIS CARD ───────────────────────────
                    _AiAnalysisCard(),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 7. DISMISS ALERT ──────────────────────────────
                    RkButton(
                      label: 'DISMISS ALERT',
                      variant: RkButtonVariant.secondary,
                      onPressed: () {
                        ref
                            .read(sentinelControllerProvider.notifier)
                            .toggleNightWatch();
                        Navigator.of(context).pop();
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 1. Status bar ─────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String clockTime;
  const _StatusBar({required this.clockTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.accentBright, size: 18),
          const SizedBox(width: AppSpacing.xs),
          RkLabel.small('STATUS: SECURED', color: AppColors.accentBright),
          const Spacer(),
          Text(
            clockTime,
            style: AppText.labelSmallCaps.copyWith(
                color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.signal_cellular_alt,
              color: AppColors.accentBright, size: 16),
        ],
      ),
    );
  }
}

// ── 3a. Patrol card ───────────────────────────────────────────────────────────

class _PatrolCard extends StatefulWidget {
  @override
  State<_PatrolCard> createState() => _PatrolCardState();
}

class _PatrolCardState extends State<_PatrolCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActiveCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _opacity,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accentBright,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          RkLabel.small('PATROL\nDISPATCH',
              color: AppColors.textSecondary),
          const SizedBox(height: 4),
          RkLabel.small('ACTIVE', color: AppColors.accentBright),
        ],
      ),
    );
  }
}

// ── 3b. Signal card ───────────────────────────────────────────────────────────

class _SignalCard extends StatefulWidget {
  @override
  State<_SignalCard> createState() => _SignalCardState();
}

class _SignalCardState extends State<_SignalCard> {
  Timer? _timer;
  int _bars = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() {
        _bars = (_bars % 3) + 2; // cycles 2 → 3 → 4 → 2 …
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActiveCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = i < _bars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 4,
                  height: 6.0 + i * 3.0,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accentBright
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          RkLabel.small('SIGNAL\nSTRENGTH',
              color: AppColors.textSecondary),
          const SizedBox(height: 4),
          RkLabel.small('$_bars / 4', color: AppColors.accentBright),
        ],
      ),
    );
  }
}

// ── 3c. Sentinel card ─────────────────────────────────────────────────────────

class _SentinelCard extends StatefulWidget {
  @override
  State<_SentinelCard> createState() => _SentinelCardState();
}

class _SentinelCardState extends State<_SentinelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActiveCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.rotate(
              angle: _ctrl.value * 2 * 3.14159,
              child: child,
            ),
            child: const Icon(Icons.shield,
                color: AppColors.accentBright, size: 20),
          ),
          const SizedBox(height: 6),
          RkLabel.small('SENTINEL\nACTIVE',
              color: AppColors.textSecondary),
          const SizedBox(height: 4),
          RkLabel.small('ARMED', color: AppColors.accentBright),
        ],
      ),
    );
  }
}

// ── Active card shell ─────────────────────────────────────────────────────────

class _ActiveCard extends StatelessWidget {
  final Widget child;
  const _ActiveCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(child: child),
    );
  }
}

// ── 4. ETA card ───────────────────────────────────────────────────────────────

class _EtaCard extends StatelessWidget {
  final String etaDisplay;
  final bool isArriving;

  const _EtaCard({required this.etaDisplay, required this.isArriving});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_police_outlined,
              color: AppColors.accentBright, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RkLabel.small('PATROL DISPATCH ACTIVE',
                color: AppColors.accentBright),
          ),
          Text(
            etaDisplay,
            style: AppText.labelSmallCaps.copyWith(
              color: isArriving ? AppColors.accentBright : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6. AI analysis card ───────────────────────────────────────────────────────

class _AiAnalysisCard extends StatefulWidget {
  @override
  State<_AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<_AiAnalysisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: const Border(
          left: BorderSide(color: AppColors.accentBright, width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pulsing dot
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: AnimatedBuilder(
              animation: _opacity,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentBright,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RkLabel.small('SYSTEM ANALYSIS',
                        color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(' · ', style: AppText.labelSmallCaps),
                    RkLabel.small('LIVE MONITORING',
                        color: AppColors.accentBright),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'AI Sentinel has cross-referenced local incident reports with current biometric spikes. Confidence level: 94%.',
                  style: AppText.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/widgets/rk_status_chip.dart';
import '../../../core/providers/settings_provider.dart';
import 'sentinel_controller.dart';

class SentinelScreen extends ConsumerStatefulWidget {
  const SentinelScreen({super.key});

  @override
  ConsumerState<SentinelScreen> createState() => _SentinelScreenState();
}

class _SentinelScreenState extends ConsumerState<SentinelScreen> {
  Timer? _timeTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timeTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    Future.microtask(
        () => ref.read(sentinelControllerProvider.notifier).loadRiskScore());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  Color _scoreColor(int? score) {
    if (score == null) return AppColors.textTertiary;
    if (score >= 75) return AppColors.riskHigh;
    if (score >= 50) return AppColors.riskMedium;
    return AppColors.textPrimary; // LOW = white per Stitch design
  }

  String _chipLabel(int? score) {
    if (score == null) return 'UNKNOWN';
    if (score >= 75) return 'CRITICAL';
    if (score >= 50) return 'ELEVATED';
    return 'PROTECTED';
  }

  @override
  Widget build(BuildContext context) {
    // TODO: wire to settingsProvider.languageCode
    final lang = ref.watch(settingsProvider).languageCode;
    // TODO: wire to sentinelControllerProvider
    final state = ref.watch(sentinelControllerProvider);
    final score = state.riskScore?.score;
    final location = state.pincode > 0
        ? '${state.pincode} · ${state.areaName.toUpperCase()}'
        : '— · ACQUIRING LOCATION';
    final scoreColor = _scoreColor(score);
    final chipLabel = _chipLabel(score);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle dot-grid background texture
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          SafeArea(
            bottom: false, // bottom nav handles its own safe area
            child: Column(
              children: [
                // ── 1. AppBar ─────────────────────────────────────────
                _AppBar(time: _currentTime),

                // ── 2. Location label ─────────────────────────────────
                const SizedBox(height: AppSpacing.sm),
                _LocationLabel(location: location),

                // ── Scrollable content ────────────────────────────────
                if (state.isLoading)
                  const Expanded(child: _LoadingSkeleton())
                else
                  Expanded(
                    child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                              // ── 3. Shield icon ──────────────────────
                              const Icon(
                                Icons.shield,
                                color: AppColors.accentBright,
                                size: 64,
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // ── 4. Risk score number ────────────────
                              Text(
                                score?.toString() ?? '--',
                                style: GoogleFonts.inter(
                                  fontSize: 96,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  color: scoreColor,
                                  letterSpacing: -1.5,
                                ),
                              ),

                              // ── 5. "YOUR CURRENT RISK SCORE" label ──
                              Text(
                                lang == 'ta'
                                    ? 'உங்கள் தற்போதைய ஆபத்து மதிப்பெண்'
                                    : 'YOUR CURRENT RISK SCORE',
                                style: AppText.labelSmallCaps.copyWith(
                                    color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // ── 6. Status chip ──────────────────────
                              RkStatusChip(
                                  label: chipLabel, color: scoreColor),
                              const SizedBox(height: AppSpacing.lg),

                              // ── 7. SOS EMERGENCY button ─────────────
                              _SosButton(lang: lang),
                              const SizedBox(height: AppSpacing.sm),

                              // ── 8. SAFETY INTELLIGENCE button ───────
                              _IntelligenceButton(lang: lang),
                              const SizedBox(height: AppSpacing.md),

                              // ── 9. Stats row ─────────────────────────
                              _StatsRow(state: state, lang: lang),
                              const SizedBox(height: AppSpacing.md),

                              // ── 10. AI monitoring banner ─────────────
                              _MonitorBanner(lang: lang),
                            ],
                          ),
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1. AppBar ─────────────────────────────────────────────────────────────────

class _AppBar extends ConsumerWidget {
  final String time;
  const _AppBar({required this.time});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Shield icon — left
          const Icon(Icons.shield, color: AppColors.accentBright, size: 20),
          const SizedBox(width: 6),
          // RAKSHAK — centered via Expanded
          Expanded(
            child: Text(
              'RAKSHAK',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 2.5,
              ),
            ),
          ),
          // Profile icon — right
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          GestureDetector(
            onTap: () => ref.read(settingsProvider.notifier).toggleLanguage(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.accentBright, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. Location label ─────────────────────────────────────────────────────────

class _LocationLabel extends StatelessWidget {
  final String location;
  const _LocationLabel({required this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.location_on,
            color: AppColors.accentBright, size: 12),
        const SizedBox(width: 4),
        Text(
          location,
          style: AppText.labelSmallCaps.copyWith(
              color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

// ── 7. SOS button ─────────────────────────────────────────────────────────────

class _SosButton extends StatelessWidget {
  final String lang;
  const _SosButton({required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/sos'),
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.alertRed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SOS',
              style: GoogleFonts.inter(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'EMERGENCY',
              style: AppText.labelSmallCaps.copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 8. Intelligence button ────────────────────────────────────────────────────

class _IntelligenceButton extends StatelessWidget {
  final String lang;
  const _IntelligenceButton({required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/intelligence'),
      child: Container(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.accentBright, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lang == 'ta' ? 'பாதுகாப்பு நுண்ணறிவு' : 'SAFETY INTELLIGENCE',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentBright,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                lang == 'ta'
                    ? 'பகுதி அச்சுறுத்தல் ஸ்கேன்'
                    : 'ugamvu · பகுதி ஸ்கேன்',
                style: AppText.labelSmallCaps.copyWith(
                    color: AppColors.textSecondary, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 9. Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SentinelState state;
  final String lang;
  const _StatsRow({required this.state, required this.lang});

  @override
  Widget build(BuildContext context) {
    // TODO: wire incidents count to real data
    const incidentsToday = 3;
    final nearestStation =
        state.riskScore?.location.split('·').last.trim() ??
            state.areaName;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: lang == 'ta' ? 'இன்றைய சம்பவங்கள்' : 'INCIDENTS TODAY',
            value: incidentsToday.toString(),
            isNumeric: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: lang == 'ta' ? 'அருகிலுள்ள நிலையம்' : 'NEAREST STATION',
            value: nearestStation,
            isNumeric: false,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isNumeric;
  const _StatCard(
      {required this.label, required this.value, required this.isNumeric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RkLabel.small(label, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: isNumeric
                ? GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  )
                : GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 10. Monitor banner ────────────────────────────────────────────────────────

class _MonitorBanner extends StatelessWidget {
  final String lang;
  const _MonitorBanner({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: RkPulse(
            color: AppColors.accentBright,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accentBright,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            lang == 'ta'
                ? 'Rakshak AI 2.4கிமீ சுற்றளவில் உள்ளூர் துயர சமிக்ஞைகளை கண்காணிக்கிறது.'
                : 'Rakshak AI is monitoring local distress signals within a 2.4km radius.',
            style: AppText.bodyMedium.copyWith(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Shimmer(width: 64, height: 64, radius: AppSpacing.radiusMd),
          const SizedBox(height: AppSpacing.md),
          _Shimmer(width: 140, height: 96, radius: AppSpacing.radiusSm),
          const SizedBox(height: AppSpacing.md),
          _Shimmer(
              width: double.infinity,
              height: 110,
              radius: AppSpacing.radiusSm),
          const SizedBox(height: AppSpacing.sm),
          _Shimmer(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              radius: AppSpacing.radiusSm),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Dot grid background ───────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';

/// Alerts Screen — placeholder matching app style.
/// Bottom nav active on Alerts.
class AlertsStubScreen extends StatelessWidget {
  const AlertsStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.shield,
                      color: AppColors.accentBright, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'RAKSHAK',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              RkLabel.small('ALERTS / எச்சரிக்கைகள்',
                  color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.lg),

              // Placeholder content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RkPulse(
                        color: AppColors.accentBright,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accentBright.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: AppColors.accentBright, size: 24),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      RkLabel.small('NO ACTIVE ALERTS',
                          color: AppColors.textSecondary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Alert feed coming soon.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';

/// Map Screen — placeholder matching app style.
/// Bottom nav active on Map.
class MapStubScreen extends StatelessWidget {
  const MapStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.shield,
                      color: AppColors.accentBright, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'RAKSHAK',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              RkLabel.small('MAP / வரைபடம்',
                  color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.lg),

              // Placeholder map area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RkPulse(
                          color: AppColors.accentBright,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accentBright.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                            child: const Icon(Icons.map_outlined,
                                color: AppColors.accentBright, size: 24),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RkLabel.small('LIVE RISK MAP',
                            color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Google Maps integration coming soon.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
import '../../../core/constants/stub_data.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/emergency_contact.dart';
import '../domain/user_service.dart';

/// Stub implementation of UserService
class UserRepository implements UserService {
  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(StubData.apiDelay);
    return StubData.defaultUser;
  }

  @override
  Future<bool> updateUserProfile(UserProfile profile) async {
    await Future.delayed(StubData.apiDelay);
    return true;
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    await Future.delayed(StubData.apiDelay);
    return StubData.emergencyContacts;
  }

  @override
  Future<bool> addEmergencyContact(EmergencyContact contact) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> removeEmergencyContact(String contactId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
import '../../../core/models/user_profile.dart';
import '../../../core/models/emergency_contact.dart';

/// User service interface
abstract class UserService {
  /// Get user profile
  Future<UserProfile> getUserProfile();

  /// Update user profile
  Future<bool> updateUserProfile(UserProfile profile);

  /// Get emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts();

  /// Add emergency contact
  Future<bool> addEmergencyContact(EmergencyContact contact);

  /// Remove emergency contact
  Future<bool> removeEmergencyContact(String contactId);
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/emergency_contact.dart';
import '../data/user_repository.dart';
import '../domain/user_service.dart';

/// User state
class UserState {
  final UserProfile? profile;
  final List<EmergencyContact> contacts;
  final bool isLoading;
  final String? error;

  const UserState({
    this.profile,
    this.contacts = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserProfile? profile,
    List<EmergencyContact>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      profile: profile ?? this.profile,
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User controller
class UserController extends StateNotifier<UserState> {
  final UserService _userService;

  UserController(this._userService) : super(const UserState());

  Future<void> loadUserProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _userService.getUserProfile();
      final contacts = await _userService.getEmergencyContacts();
      state = state.copyWith(
        profile: profile,
        contacts: contacts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      final success = await _userService.addEmergencyContact(contact);
      if (success) {
        state = state.copyWith(
          contacts: [...state.contacts, contact],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeEmergencyContact(String contactId) async {
    try {
      final success = await _userService.removeEmergencyContact(contactId);
      if (success) {
        state = state.copyWith(
          contacts: state.contacts.where((c) => c.id != contactId).toList(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// User service provider
final userServiceProvider = Provider<UserService>((ref) {
  return UserRepository();
});

/// User controller provider
final userControllerProvider =
    StateNotifierProvider<UserController, UserState>((ref) {
  return UserController(ref.watch(userServiceProvider));
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/providers/settings_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import 'user_controller.dart';

class UserSpaceScreen extends ConsumerStatefulWidget {
  const UserSpaceScreen({super.key});

  @override
  ConsumerState<UserSpaceScreen> createState() => _UserSpaceScreenState();
}

class _UserSpaceScreenState extends ConsumerState<UserSpaceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(userControllerProvider.notifier).loadUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    // TODO: wire to settingsProvider.languageCode
    final lang = ref.watch(settingsProvider).languageCode;
    // TODO: wire to userControllerProvider
    final state = ref.watch(userControllerProvider);
    // Phone number from auth session
    final authPhone = ref.watch(authControllerProvider).phoneNumber;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.accentBright, strokeWidth: 2),
        ),
      );
    }

    // TODO: wire to UserProfile model
    final user = state.profile;
    final userName = user?.name ?? 'Anjali Devi'; // TODO: wire to UserProfile.name
    // Phone: prefer auth session phone, fall back to profile phone
    final rawPhone = authPhone ?? user?.phone;
    final userPhone = _formatPhone(rawPhone);
    final contacts = state.contacts; // TODO: wire to UserState.contacts

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── FIX 1: Header row — avatar constrained, no overflow ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column — all text, takes remaining space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RkLabel.small(
                          'USER SPACE / பயனர் பகுதி',
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // User name — 32px bold per spec
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userPhone,
                          style: AppText.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            RkPulse(
                              color: AppColors.accentBright,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentBright,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: RkLabel.small(
                                'SYSTEM ARMED & WATCHING',
                                color: AppColors.accentBright,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Avatar — 44×44, fixed size, right-aligned
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.accentBright, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Scans performed card (teal bg) ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentBright,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner_outlined,
                        color: AppColors.accentDark, size: 28),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '12', // TODO: wire to UserProfile.scanCount
                      style: GoogleFonts.inter(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentDark,
                        height: 1.0,
                      ),
                    ),
                    RkLabel.small(
                      lang == 'ta'
                          ? 'SCANS PERFORMED / ஸ்கேன்கள் செய்யப்பட்டன'
                          : 'SCANS PERFORMED',
                      color: AppColors.accentDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Emergency Contacts header ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lang == 'ta'
                          ? 'Emergency Contacts / அவசர தொடர்புகள்'
                          : 'Emergency Contacts / அவசர தொடர்புகள்',
                      style: AppText.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: RkLabel.small(
                      lang == 'ta' ? 'EDIT / திருத்து' : 'EDIT / திருத்து',
                      color: AppColors.accentBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── PRIMARY contacts ──────────────────────────────────────
              RkLabel.small('PRIMARY', color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.xs),

              if (contacts.isEmpty) ...[
                _ContactCard(
                  name: 'Mom / அம்மா',
                  phone: '+91 8XXXX XXXXX',
                  gender: 'female',
                  lang: lang,
                ),
                const SizedBox(height: AppSpacing.xs),
                _ContactCard(
                  name: 'Dad / அப்பா',
                  phone: '+91 8XXXX XXXXX',
                  gender: 'male',
                  lang: lang,
                ),
              ] else ...[
                ...contacts
                    .where((c) =>
                        c.relationship.toLowerCase().contains('mother') ||
                        c.relationship.toLowerCase().contains('father') ||
                        c.relationship.toLowerCase().contains('primary'))
                    .map((c) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _ContactCard(
                            name: c.name,
                            phone: c.phone,
                            gender: c.relationship
                                    .toLowerCase()
                                    .contains('mother')
                                ? 'female'
                                : 'male',
                            lang: lang,
                          ),
                        )),
              ],

              const SizedBox(height: AppSpacing.md),

              // ── SECONDARY contacts ────────────────────────────────────
              RkLabel.small('SECONDARY', color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.xs),

              if (contacts.isEmpty) ...[
                _ContactCard(
                  name: 'Dad / அப்பா',
                  phone: '+91 8XXXX XXXXX',
                  gender: 'male',
                  lang: lang,
                ),
              ] else ...[
                ...contacts
                    .where((c) =>
                        !c.relationship.toLowerCase().contains('mother') &&
                        !c.relationship.toLowerCase().contains('father') &&
                        !c.relationship.toLowerCase().contains('primary'))
                    .map((c) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _ContactCard(
                            name: c.name,
                            phone: c.phone,
                            gender: 'male',
                            lang: lang,
                          ),
                        )),
              ],

              const SizedBox(height: AppSpacing.md),

              // ── OFFICIAL contact ──────────────────────────────────────
              RkLabel.small('OFFICIAL / அதிகாரி',
                  color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.xs),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.20),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_police_outlined,
                        color: AppColors.riskHigh, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'ta'
                                ? 'Police / காவல்துறை'
                                : 'Police / காவல்துறை',
                            style: AppText.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Dial 100',
                            style: AppText.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/sos'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.alertRed,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'SOS CALL',
                          style: AppText.labelSmallCaps.copyWith(
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formats a raw phone number for display.
/// - Strips leading +91 or 91 prefix if present
/// - Adds "+91 " prefix
/// - Inserts a space after the 5th digit: "+91 XXXXX XXXXX"
/// - Returns "Phone not set" if null or empty
String _formatPhone(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Phone not set';
  var digits = raw.trim().replaceAll(RegExp(r'\D'), '');
  // Strip country code
  if (digits.startsWith('91') && digits.length > 10) {
    digits = digits.substring(2);
  }
  if (digits.length == 10) {
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }
  // Already formatted or unknown format — just prepend +91 if missing
  if (raw.startsWith('+91')) return raw;
  return '+91 $raw';
}

// ── Contact card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String gender;
  final String lang;

  const _ContactCard({
    required this.name,
    required this.phone,
    required this.gender,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            gender == 'female' ? Icons.female : Icons.male,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppText.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(phone, style: AppText.bodySmall),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: AppColors.accentBright, width: 1),
              ),
              child: Text(
                'ALERT',
                style: AppText.labelSmallCaps.copyWith(
                  color: AppColors.accentBright,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../config/api.dart' as api;
import '../../../core/constants/stub_data.dart';
import '../domain/sos_service.dart';

/// Live SOS repository — POSTs to /sos/live with real GPS, falls back gracefully.
class SosRepository implements SosService {
  bool _sosActive = false;
  String? _activeSosId;
  String? _activePincode;

  /// Try to get GPS coordinates within 5 seconds.
  /// Returns null if permission denied, timed out, or on web.
  /// Never throws — SOS must never be blocked by location failure.
  Future<({double lat, double lng})?> _getLocation() async {
    if (kIsWeb) return null; // Geolocator GPS not reliable on web

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));

      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null; // timeout or any error — proceed without coordinates
    }
  }

  @override
  Future<bool> triggerSos({int? pincode}) async {
    // Get GPS — null if unavailable (never blocks SOS)
    final coords = await _getLocation();

    try {
      final body = <String, dynamic>{
        'lat':       coords?.lat,   // null if location unavailable
        'lng':       coords?.lng,
        'latitude':  coords?.lat,   // also send legacy field names for backend compat
        'longitude': coords?.lng,
        'risk_level': 'HIGH',
        'status':     'active',
        'timestamp':  DateTime.now().toIso8601String(),
      };

      // Include pincode (from Judge Mode or sentinel GPS-derived value)
      if (pincode != null) {
        body['pincode']    = pincode.toString();
        body['zone_name']  = pincode.toString(); // backend sets zone_name = pincode
        _activePincode     = pincode.toString();
      }

      final res = await http
          .post(
            Uri.parse(api.sosLive),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _sosActive = true;
        try {
          final resp = jsonDecode(res.body) as Map<String, dynamic>;
          _activeSosId = resp['sos_id']?.toString();
        } catch (_) {}
        return true;
      }
    } catch (_) {}

    // Fallback: mark active locally so the UI proceeds even if network fails
    _sosActive = true;
    return true;
  }

  @override
  Future<bool> cancelSos({String? userPhone}) async {
    if (_activeSosId != null) {
      try {
        await http
            .patch(Uri.parse('${api.sosResolve}/$_activeSosId'))
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    }

    // Notify backend — patrol can follow up via phone
    try {
      await http
          .post(
            Uri.parse(api.sosCancelled),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sos_id':     _activeSosId ?? '',
              'user_phone': userPhone ?? '',
              'pincode':    _activePincode ?? '',
              'reason':     'User cancelled',
              'timestamp':  DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    _sosActive = false;
    _activeSosId = null;
    _activePincode = null;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getSosStatus() async {
    return _sosActive ? StubData.sosActive : StubData.sosSecured;
  }

  @override
  Future<bool> isSosActive() async => _sosActive;
}
/// SOS service interface
abstract class SosService {
  /// Trigger SOS alert with optional pincode override (from Judge Mode)
  Future<bool> triggerSos({int? pincode});

  /// Cancel SOS alert — notifies backend with user phone for patrol follow-up
  Future<bool> cancelSos({String? userPhone});

  /// Get SOS status
  Future<Map<String, dynamic>> getSosStatus();

  /// Check if SOS is active
  Future<bool> isSosActive();
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/providers/settings_provider.dart';
import 'sos_controller.dart';

/// SOS Screen — Stitch design:
/// Phase 1: Full screen alert red, asterisk/star, "Contacting Emergency Services..."
/// Phase 2 (Night-Watch Secured): STATUS: SECURED, "Help is on the way", DISMISS ALERT,
/// current time + signal strength row, PATROL DISPATCH ACTIVE badge.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _isPhase2 = false;
  Timer? _timeTimer;
  String _currentTime = '';
  late AnimationController _starCtrl;
  late Animation<double> _starOpacity;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timeTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _starOpacity = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _starCtrl, curve: Curves.linear),
    );

    // TODO: wire to sosControllerProvider.triggerSos()
    Future.delayed(const Duration(milliseconds: 100), () {
      ref.read(sosControllerProvider.notifier).triggerSos();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isPhase2 = true);
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: wire to settingsProvider.languageCode
    final lang = ref.watch(settingsProvider).languageCode;
    // TODO: wire to sosControllerProvider for status
    ref.watch(sosControllerProvider);

    return PopScope(
      canPop: _isPhase2,
      child: Scaffold(
        backgroundColor:
            _isPhase2 ? AppColors.background : AppColors.alertRed,
        body: SafeArea(
          child: _isPhase2
              ? _Phase2(
                  lang: lang,
                  currentTime: _currentTime,
                )
              : _Phase1(
                  lang: lang,
                  starOpacity: _starOpacity,
                ),
        ),
      ),
    );
  }
}

// ── Phase 1: Contacting ───────────────────────────────────────────────────────

class _Phase1 extends StatelessWidget {
  final String lang;
  final Animation<double> starOpacity;

  const _Phase1({required this.lang, required this.starOpacity});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated asterisk — 120px, white, pulsing
            AnimatedBuilder(
              animation: starOpacity,
              builder: (_, child) =>
                  Opacity(opacity: starOpacity.value, child: child),
              child: Text(
                '*',
                style: GoogleFonts.inter(
                  fontSize: 120,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // "Contacting Emergency Services..."
            Text(
              lang == 'ta'
                  ? 'அவசர சேவைகளை தொடர்பு கொள்கிறது...'
                  : 'Contacting Emergency Services...',
              style: AppText.headlineSmall.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // RAKSHAK SENTINEL ACTIVE
            RkLabel.small(
              'RAKSHAK SENTINEL ACTIVE',
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 2: Secured ──────────────────────────────────────────────────────────

class _Phase2 extends ConsumerWidget {
  final String lang;
  final String currentTime;

  const _Phase2({required this.lang, required this.currentTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── STATUS: SECURED header ──────────────────────────────────
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shield,
                      color: AppColors.accentBright, size: 36),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.check,
                        color: AppColors.accentBright, size: 14),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              RkLabel.small('STATUS: SECURED',
                  color: AppColors.accentBright),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── "Help is on the way." ─────────────────────────────────
          Text(
            lang == 'ta'
                ? 'உதவி வந்து கொண்டிருக்கிறது.'
                : 'Help is on the way.',
            style: AppText.displayLarge.copyWith(fontSize: 44),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Body text ─────────────────────────────────────────────
          Text(
            'Your location is secured. Help is on the way. Please stay in a well-lit place.',
            style: AppText.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'உங்கள் இருப்பிடம் பாதுகாப்பானது. உதவி வந்து கொண்டிருக்கிறது. வெளிச்சமான இடத்தில் இருக்கவும்.',
            style: AppText.bodyMedium.copyWith(
                color: AppColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── PATROL DISPATCH ACTIVE ────────────────────────────────
          Row(
            children: [
              RkPulse(
                color: AppColors.accentBright,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentBright,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              RkLabel.small('PATROL DISPATCH ACTIVE',
                  color: AppColors.accentBright),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── DISMISS ALERT ─────────────────────────────────────────
          RkButton(
            label: lang == 'ta' ? 'DISMISS ALERT' : 'DISMISS ALERT',
            variant: RkButtonVariant.secondary,
            onPressed: () async {
              await ref.read(sosControllerProvider.notifier).markSecured();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'SOS cancelled. Your number has been shared with the nearest patrol in case they need to follow up.',
                  ),
                  duration: Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.go('/sentinel');
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Time + Signal row ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RkLabel.small('CURRENT TIME',
                        color: AppColors.textSecondary),
                    const SizedBox(height: 4),
                    Text(
                      currentTime,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RkLabel.small('SIGNAL STRENGTH',
                        color: AppColors.textSecondary),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Icon(
                            Icons.signal_cellular_alt,
                            color: AppColors.accentBright,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sos_repository.dart';
import '../domain/sos_service.dart';
import '../../../core/widgets/judge_mode_overlay.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../sentinel/presentation/sentinel_controller.dart';

/// SOS state
enum SosStatus {
  idle,
  triggering,
  active,
  secured,
  error,
}

class SosState {
  final SosStatus status;
  final String? error;
  final Map<String, dynamic>? statusData;

  const SosState({
    this.status = SosStatus.idle,
    this.error,
    this.statusData,
  });

  SosState copyWith({
    SosStatus? status,
    String? error,
    Map<String, dynamic>? statusData,
  }) {
    return SosState(
      status: status ?? this.status,
      error: error,
      statusData: statusData ?? this.statusData,
    );
  }
}

/// SOS controller
class SosController extends StateNotifier<SosState> {
  final SosService _sosService;
  final Ref _ref;

  SosController(this._sosService, this._ref) : super(const SosState());

  Future<void> triggerSos() async {
    state = state.copyWith(status: SosStatus.triggering);

    // Judge mode pincode takes priority; fall back to sentinel GPS-derived pincode
    final judgePin = _ref.read(judgePincodeProvider);
    int? pincode = judgePin;
    if (pincode == null) {
      final sentinelPin = _ref.read(sentinelControllerProvider).pincode;
      if (sentinelPin > 0) pincode = sentinelPin;
    }

    try {
      final success = await _sosService.triggerSos(pincode: pincode);
      if (success) {
        final statusData = await _sosService.getSosStatus();
        state = state.copyWith(
          status: SosStatus.active,
          statusData: statusData,
        );
      } else {
        state = state.copyWith(
          status: SosStatus.error,
          error: 'Failed to trigger SOS',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SosStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> markSecured() async {
    try {
      final phone = _ref.read(authControllerProvider).phoneNumber;
      await _sosService.cancelSos(userPhone: phone);
      state = state.copyWith(status: SosStatus.secured);
    } catch (e) {
      state = state.copyWith(
        status: SosStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const SosState();
  }
}

/// SOS service provider
final sosServiceProvider = Provider<SosService>((ref) {
  return SosRepository();
});

/// SOS controller provider
final sosControllerProvider =
    StateNotifierProvider<SosController, SosState>((ref) {
  return SosController(ref.watch(sosServiceProvider), ref);
});
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';
import '../models/zone.dart';

/// Returns the risk level for a given pincode string, or 'LOW' as default.
String _riskForPincode(String pincode) {
  final zone = Zone.chennaiZones.firstWhere(
    (z) => z.pincode == pincode,
    orElse: () => const Zone(pincode: '', name: '', riskLevel: 'LOW', lat: 0, lng: 0),
  );
  return zone.riskLevel;
}

/// Fill + border colors per risk level, matching the dashboard exactly.
/// Dashboard fills: HIGH=0.20, MEDIUM=0.15, LOW=0.10
/// Dashboard weights: HIGH=1.5, MEDIUM=1.0, LOW=0.8
({Color fill, Color border, double strokeWidth}) _colorsForRisk(String risk) {
  switch (risk.toUpperCase()) {
    case 'HIGH':
      return (
        fill:        const Color(0xFFef4444).withValues(alpha: 0.20),
        border:      const Color(0xFFef4444).withValues(alpha: 0.90),
        strokeWidth: 1.5,
      );
    case 'MEDIUM':
      return (
        fill:        const Color(0xFFf59e0b).withValues(alpha: 0.15),
        border:      const Color(0xFFf59e0b).withValues(alpha: 0.90),
        strokeWidth: 1.0,
      );
    case 'LOW':
      return (
        fill:        const Color(0xFF22c55e).withValues(alpha: 0.10),
        border:      const Color(0xFF22c55e).withValues(alpha: 0.90),
        strokeWidth: 0.8,
      );
    default: // unknown pincode — treat as LOW
      return (
        fill:        const Color(0xFF22c55e).withValues(alpha: 0.10),
        border:      const Color(0xFF22c55e).withValues(alpha: 0.70),
        strokeWidth: 0.8,
      );
  }
}

/// Parses Final_Chennai_Pincode.kml from assets and returns a list of
/// [Polygon] objects coloured by risk level.
///
/// [riskOverrides] — optional map of pincode → risk level to override
/// the defaults from [Zone.chennaiZones].
Future<List<Polygon>> loadKmlZones({Map<String, String>? riskOverrides}) async {
  final kmlString = await rootBundle.loadString('assets/Final_Chennai_Pincode.kml');
  final document  = XmlDocument.parse(kmlString);
  final placemarks = document.findAllElements('Placemark');

  final polygons = <Polygon>[];

  for (final placemark in placemarks) {
    // Extract pincode from SimpleData or <name>
    final simpleData = placemark
        .findAllElements('SimpleData')
        .where((e) => e.getAttribute('name') == 'Pincode')
        .firstOrNull;
    final pincode = simpleData?.innerText.trim() ??
        placemark.findElements('name').firstOrNull?.innerText.trim() ??
        '';

    final coordsEl = placemark.findAllElements('coordinates').firstOrNull;
    if (coordsEl == null) continue;

    final points = coordsEl.innerText
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.contains(','))
        .map((pair) {
          final parts = pair.split(',');
          if (parts.length < 2) return null;
          final lng = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lat == null || lng == null) return null;
          return LatLng(lat, lng);
        })
        .whereType<LatLng>()
        .toList();

    if (points.length < 3) continue;

    final risk   = riskOverrides?[pincode] ?? _riskForPincode(pincode);
    final colors = _colorsForRisk(risk);

    polygons.add(Polygon(
      points:            points,
      color:             colors.fill,
      borderColor:       colors.border,
      borderStrokeWidth: colors.strokeWidth,
    ));
  }

  return polygons;
}
/// Timing constants used across the web dashboard.
class TimingConstants {
  TimingConstants._();

  /// How often the live clock widget refreshes.
  static const Duration clockUpdateInterval = Duration(seconds: 1);

  /// How often the heatmap data auto-refreshes.
  static const Duration heatmapRefreshInterval = Duration(minutes: 5);
}

/// Map constants for the Chennai heatmap.
class MapConstants {
  MapConstants._();

  static const double chennaiLat  = 13.0827;
  static const double chennaiLng  = 80.2707;
  static const double defaultZoom = 11.0;

  /// Radius in metres for each heatmap circle.
  static const double heatmapRadius  = 500.0;

  /// Base opacity multiplied by the risk weight.
  static const double heatmapOpacity = 0.6;
}

/// Risk weight constants used when rendering heatmap circles.
class RiskConstants {
  RiskConstants._();

  static const double highWeight   = 1.0;
  static const double mediumWeight = 0.6;
  static const double lowWeight    = 0.3;
}
class SosAlert {
  final String id;
  final String zoneName;
  final String riskLevel;
  final DateTime timestamp;
  final String status;
  final double? lat;
  final double? lng;
  final String? pincode;
  final String? sosId;
  final String? userPhone;

  const SosAlert({
    required this.id,
    required this.zoneName,
    required this.riskLevel,
    required this.timestamp,
    required this.status,
    this.lat,
    this.lng,
    this.pincode,
    this.sosId,
    this.userPhone,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    final rawZoneName = json['zone_name']?.toString();
    final pincode     = json['pincode']?.toString();

    // If zone_name is a raw 6-digit pincode, resolve it to an area name
    String resolvedName;
    if (rawZoneName != null && RegExp(r'^\d{6}$').hasMatch(rawZoneName)) {
      resolvedName = '${_pincodeNames[rawZoneName] ?? rawZoneName} ($rawZoneName)';
    } else {
      resolvedName = rawZoneName ?? pincode ?? 'Unknown Zone';
    }

    return SosAlert(
      id:        json['sos_id']?.toString() ?? json['id']?.toString() ?? '',
      zoneName:  resolvedName,
      riskLevel: json['risk_level']?.toString() ?? 'HIGH',
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status:    json['status']?.toString() ?? 'dispatched',
      lat:       (json['latitude'] as num?)?.toDouble(),
      lng:       (json['longitude'] as num?)?.toDouble(),
      pincode:   pincode,
      sosId:     json['sos_id']?.toString(),
      userPhone: json['user_phone']?.toString(),
    );
  }

  // Pincode → area name lookup (matches judge_mode_overlay.dart dropdown)
  static const Map<String, String> _pincodeNames = {
    '600001': 'Parrys Corner',  '600002': 'Sowcarpet',
    '600003': 'Park Town',      '600004': 'Mylapore',
    '600005': 'Chintadripet',   '600006': 'Chepauk',
    '600007': 'Perambur',       '600008': 'Chepauk',
    '600009': 'Kilpauk',        '600010': 'Vepery',
    '600011': 'Perambur',       '600012': 'Tondiarpet',
    '600013': 'Tiruvottiyur',   '600015': 'Padi',
    '600017': 'T. Nagar',       '600018': 'Kodambakkam',
    '600019': 'Ennore',         '600020': 'Anna Nagar',
    '600024': 'Ashok Nagar',    '600028': 'Nungambakkam',
    '600029': 'Aminjikarai',    '600032': 'Vadapalani',
    '600033': 'Saidapet',       '600034': 'Teynampet',
    '600035': 'Alandur',        '600036': 'St. Thomas Mount',
    '600040': 'Virugambakkam',  '600042': 'Thiruvanmiyur',
    '600044': 'Tambaram',       '600045': 'Pallavaram',
    '600050': 'Arumbakkam',     '600053': 'Ambattur',
    '600056': 'Porur',          '600058': 'Washermanpet',
    '600061': 'Chromepet',      '600064': 'Vandalur',
    '600078': 'Valasaravakkam', '600081': 'Manali',
    '600082': 'Madhavaram',     '600083': 'Villivakkam',
    '600090': 'Velachery',      '600096': 'OMR',
    '600099': 'Poonamallee',    '600118': 'Kathivakkam',
  };

  // No mock fallback — return empty list when backend is unavailable
  static List<SosAlert> mockAlerts() => [];
}
class Patrol {
  final String id;
  final String vehicle;
  final String status;
  final String zone;

  const Patrol({
    required this.id,
    required this.vehicle,
    required this.status,
    required this.zone,
  });

  factory Patrol.fromJson(Map<String, dynamic> json) {
    return Patrol(
      id:      json['patrol_id']?.toString() ?? '',
      vehicle: json['vehicle']?.toString() ?? '',
      status:  json['status']?.toString() ?? 'patrolling',
      zone:    json['zone']?.toString() ?? '',
    );
  }
}
class Zone {
  final String pincode;
  final String name;
  final String riskLevel;
  final double lat;
  final double lng;

  const Zone({
    required this.pincode,
    required this.name,
    required this.riskLevel,
    required this.lat,
    required this.lng,
  });

  static const List<Zone> chennaiZones = [
    Zone(pincode: '600001', name: 'Parrys',       riskLevel: 'HIGH',   lat: 13.0908, lng: 80.2866),
    Zone(pincode: '600006', name: 'Vepery',        riskLevel: 'HIGH',   lat: 13.0900, lng: 80.2757),
    Zone(pincode: '600007', name: 'Perambur',      riskLevel: 'HIGH',   lat: 13.1186, lng: 80.2487),
    Zone(pincode: '600058', name: 'Royapuram',     riskLevel: 'HIGH',   lat: 13.1127, lng: 80.2966),
    Zone(pincode: '600081', name: 'Manali',        riskLevel: 'HIGH',   lat: 13.1675, lng: 80.2617),
    Zone(pincode: '600002', name: 'Park Town',     riskLevel: 'MEDIUM', lat: 13.0827, lng: 80.2707),
    Zone(pincode: '600003', name: 'Triplicane',    riskLevel: 'MEDIUM', lat: 13.0569, lng: 80.2787),
    Zone(pincode: '600011', name: 'Perambur',      riskLevel: 'MEDIUM', lat: 13.0732, lng: 80.2609),
    Zone(pincode: '600015', name: 'Mylapore',      riskLevel: 'LOW',    lat: 13.0339, lng: 80.2707),
    Zone(pincode: '600017', name: 'Adyar',         riskLevel: 'LOW',    lat: 13.0067, lng: 80.2570),
    Zone(pincode: '600032', name: 'T Nagar',       riskLevel: 'LOW',    lat: 13.0350, lng: 80.2323),
    Zone(pincode: '600040', name: 'Anna Nagar',    riskLevel: 'LOW',    lat: 13.0850, lng: 80.2101),
    Zone(pincode: '600024', name: 'Velachery',     riskLevel: 'LOW',    lat: 12.9815, lng: 80.2209),
    Zone(pincode: '600028', name: 'Besant Nagar',  riskLevel: 'LOW',    lat: 12.9995, lng: 80.2666),
  ];
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

void main() {
  runApp(const RakshakAdminApp());
}

class RakshakAdminApp extends StatelessWidget {
  const RakshakAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAKSHAK Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          surface: const Color(0xFF111827),
        ),
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _currentTime = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')} IST';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF111827),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield, color: Colors.blue, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'RAKSHAK',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Safety Intelligence Platform',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Nav Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'COMMAND',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Nav Items
                _NavItem(
                  icon: Icons.map,
                  label: 'Risk Map',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
                  icon: Icons.report,
                  label: 'Incidents',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: Icons.location_city,
                  label: 'Areas',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
                const Spacer(),
                // Live SOS Feed
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE SOS FEED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(4, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'T.Nagar • Theft • ${i + 1}m ago',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'CHENNAI COMMAND CENTER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _currentTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _showBroadcastDialog,
                        icon: const Icon(Icons.warning_amber, size: 18),
                        label: const Text('BROADCAST ALERT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export'),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'pdf', child: Text('PDF')),
                          const PopupMenuItem(value: 'csv', child: Text('CSV')),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const RiskMapPage();
      case 1:
        return const AnalyticsPage();
      case 2:
        return const IncidentsPage();
      case 3:
        return const AreasPage();
      default:
        return const Center(child: Text('Settings'));
    }
  }

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Broadcast Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Target Area'),
              items: ['All Areas', 'T.Nagar', 'Egmore', 'Parrys Corner']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alert Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Severity: '),
                const Spacer(),
                ChoiceChip(label: const Text('Low'), selected: true, onSelected: (_) {}),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Medium'), selected: false, onSelected: (_) {}),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Critical'), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SEND BROADCAST'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiskMapPage extends StatefulWidget {
  const RiskMapPage({super.key});

  @override
  State<RiskMapPage> createState() => _RiskMapPageState();
}

class _RiskMapPageState extends State<RiskMapPage> {
  bool _showParrys = true;
  bool _showPerambur = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.sos,
                  title: 'SOS Signals Today',
                  value: '142',
                  trend: '↑18% today',
                  trendColor: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning,
                  title: 'High Risk Zones',
                  value: '6',
                  trend: '↑2',
                  trendColor: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer,
                  title: 'Avg Response Time',
                  value: '14.3 min',
                  trend: '↓6%',
                  trendColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Map Card
          Container(
            height: 500,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'LIVE RISK MAP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'HEATMAP ACTIVE',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_showParrys)
                        _AreaChip(
                          label: 'Parrys Corner — CRITICAL',
                          color: Colors.red,
                          onClose: () => setState(() => _showParrys = false),
                        ),
                      if (_showPerambur) ...[
                        const SizedBox(width: 8),
                        _AreaChip(
                          label: 'Perambur — HIGH',
                          color: Colors.orange,
                          onClose: () => setState(() => _showPerambur = false),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Map
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: const LatLng(13.0827, 80.2707),
                          initialZoom: 11,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: const LatLng(13.0827, 80.2707),
                                radius: 5000,
                                color: Colors.red.withValues(alpha: 0.3),
                                borderColor: Colors.red,
                                borderStrokeWidth: 2,
                              ),
                              CircleMarker(
                                point: const LatLng(13.1, 80.25),
                                radius: 3000,
                                color: Colors.orange.withValues(alpha: 0.3),
                                borderColor: Colors.orange,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'zoom_in',
                              onPressed: () {},
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'zoom_out',
                              onPressed: () {},
                              child: const Icon(Icons.remove),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final Color trendColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const Spacer(),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  color: trendColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onClose;

  const _AreaChip({
    required this.label,
    required this.color,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7-Day SOS Trend',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 120),
                                  const FlSpot(1, 135),
                                  const FlSpot(2, 128),
                                  const FlSpot(3, 145),
                                  const FlSpot(4, 138),
                                  const FlSpot(5, 152),
                                  const FlSpot(6, 142),
                                ],
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incident Types',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: 40,
                                color: Colors.red,
                                title: 'Theft',
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 30,
                                color: Colors.orange,
                                title: 'Assault',
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 20,
                                color: Colors.yellow,
                                title: 'Vandalism',
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 10,
                                color: Colors.blue,
                                title: 'Other',
                                radius: 60,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk by Area',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const areas = [
                                'T.Nagar',
                                'Egmore',
                                'Parrys',
                                'Anna Nagar',
                                'Perambur',
                                'Adyar'
                              ];
                              return Text(
                                areas[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(6, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: [85, 72, 90, 65, 78, 68][i].toDouble(),
                              color: Colors.blue,
                              width: 30,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentsPage extends StatelessWidget {
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incident Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Colors.blue.withValues(alpha: 0.1),
              ),
              columns: const [
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Area')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Assigned Officer')),
              ],
              rows: [
                _buildIncidentRow('09:15', 'T.Nagar', 'Theft', 'Open', 'Officer Kumar'),
                _buildIncidentRow('08:45', 'Egmore', 'Assault', 'Resolved', 'Officer Priya'),
                _buildIncidentRow('08:30', 'Parrys Corner', 'Vandalism', 'Open', 'Officer Raj'),
                _buildIncidentRow('07:50', 'Anna Nagar', 'Theft', 'Open', 'Officer Devi'),
                _buildIncidentRow('07:20', 'Perambur', 'Assault', 'Resolved', 'Officer Suresh'),
                _buildIncidentRow('06:55', 'Adyar', 'Theft', 'Open', 'Officer Lakshmi'),
                _buildIncidentRow('06:30', 'T.Nagar', 'Vandalism', 'Resolved', 'Officer Kumar'),
                _buildIncidentRow('06:10', 'Egmore', 'Theft', 'Open', 'Officer Priya'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildIncidentRow(
    String time,
    String area,
    String type,
    String status,
    String officer,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(time)),
        DataCell(Text(area)),
        DataCell(Text(type)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Open'
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Open' ? Colors.red : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text(officer)),
      ],
    );
  }
}

class AreasPage extends StatefulWidget {
  const AreasPage({super.key});

  @override
  State<AreasPage> createState() => _AreasPageState();
}

class _AreasPageState extends State<AreasPage> {
  final List<Map<String, dynamic>> _areas = [
    {'name': 'T.Nagar', 'risk': 85, 'lastIncident': '2h ago', 'enabled': true},
    {'name': 'Egmore', 'risk': 72, 'lastIncident': '4h ago', 'enabled': true},
    {'name': 'Parrys Corner', 'risk': 90, 'lastIncident': '1h ago', 'enabled': true},
    {'name': 'Anna Nagar', 'risk': 65, 'lastIncident': '6h ago', 'enabled': true},
    {'name': 'Perambur', 'risk': 78, 'lastIncident': '3h ago', 'enabled': false},
    {'name': 'Adyar', 'risk': 68, 'lastIncident': '5h ago', 'enabled': true},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitored Areas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ..._areas.asMap().entries.map((entry) {
            final index = entry.key;
            final area = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      area['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Risk Score: ', style: TextStyle(fontSize: 12)),
                            Text(
                              '${area['risk']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: area['risk'] / 100,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            area['risk'] > 80
                                ? Colors.red
                                : area['risk'] > 70
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Last incident: ${area['lastIncident']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                  Switch(
                    value: area['enabled'],
                    onChanged: (value) {
                      setState(() {
                        _areas[index]['enabled'] = value;
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;
import '../models/sos_alert.dart';
import '../models/zone.dart';
import '../services/api_service.dart';
import '../utils/kml_parser.dart';

class OptimisedRouteScreen extends StatefulWidget {
  final LatLng officerPos;
  final List<SosAlert> alerts;

  const OptimisedRouteScreen({
    super.key,
    required this.officerPos,
    required this.alerts,
  });

  @override
  State<OptimisedRouteScreen> createState() => _OptimisedRouteScreenState();
}

class _OptimisedRouteScreenState extends State<OptimisedRouteScreen> {
  static const _bg      = Color(0xFF0d1117);
  static const _surface = Color(0xFF161b22);
  static const _border  = Color(0xFF30363d);
  static const _teal    = Color(0xFF00d4b4);
  static const _textPri = Color(0xFFf0f6fc);
  static const _textMut = Color(0xFF8b949e);

  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _stops = [];
  bool _loading = true;
  String _totalDist = '—';
  String _eta = '—';
  late Future<List<Polygon>> _kmlZonesFuture;

  // Backend route data
  String? _backendArea;
  double? _backendDistKm;
  int?    _backendEtaMins;
  String? _backendMapsUrl;

  // Patrol optimizer data
  List<Map<String, dynamic>> _deploymentZones = [];
  bool _optimizerLoading = false;

  @override
  void initState() {
    super.initState();
    _kmlZonesFuture = loadKmlZones();
    _buildRoute();
    _fetchBackendRoute();
    _fetchPatrolOptimizer();
  }

  Future<void> _fetchPatrolOptimizer() async {
    setState(() => _optimizerLoading = true);

    // Build zone payload from high/medium risk zones
    final zones = Zone.chennaiZones
        .where((z) => z.riskLevel == 'HIGH' || z.riskLevel == 'MEDIUM')
        .map((z) => {
              'pincode': z.pincode,
              'name': z.name,
              'lat': z.lat,
              'lng': z.lng,
              'risk_level': z.riskLevel,
            })
        .toList();

    // Build patrol payload from current alerts as proxy for active patrols
    final patrols = widget.alerts
        .where((a) => a.lat != null && a.lng != null)
        .map((a) => {
              'id': a.id,
              'lat': a.lat,
              'lng': a.lng,
              'status': a.status,
            })
        .toList();

    try {
      final data = await ApiService.fetchPatrolOptimizedRoutes(
        zones: zones,
        patrols: patrols,
      );

      // Response may contain deployment_zones, suggested_zones, zones, or assignments
      final raw = data['deployment_zones']
          ?? data['suggested_zones']
          ?? data['zones']
          ?? data['assignments']
          ?? [];

      if (mounted && raw is List) {
        setState(() {
          _deploymentZones = raw
              .whereType<Map<String, dynamic>>()
              .toList();
        });
      }
    } catch (_) {
      // Optimizer endpoint not yet live — fail silently
    } finally {
      if (mounted) setState(() => _optimizerLoading = false);
    }
  }

  Future<void> _fetchBackendRoute() async {
    final primary = widget.alerts.firstWhere(
      (a) => a.lat != null && a.lng != null,
      orElse: () => SosAlert(id: '', zoneName: '', riskLevel: '', timestamp: DateTime.now(), status: ''),
    );
    if (primary.lat == null) return;

    final sosId = primary.sosId ?? primary.id;
    if (sosId.isEmpty) return;

    final data = await ApiService.fetchRoute(
      fromLat: widget.officerPos.latitude,
      fromLng: widget.officerPos.longitude,
      toLat:   primary.lat!,
      toLng:   primary.lng!,
      sosId:   sosId,
    );

    if (mounted && data.isNotEmpty) {
      setState(() {
        _backendArea    = data['destination_area']?.toString();
        _backendDistKm  = (data['distance_km'] as num?)?.toDouble();
        _backendEtaMins = (data['eta_minutes'] as num?)?.toInt();
        _backendMapsUrl = data['google_maps_url']?.toString();
      });
    }
  }

  List<LatLng> _greedyOrder(LatLng start, List<LatLng> targets) {
    final remaining = List<LatLng>.from(targets);
    final ordered = <LatLng>[];
    var current = start;
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final da = _dist(current, a);
        final db = _dist(current, b);
        return da.compareTo(db);
      });
      ordered.add(remaining.removeAt(0));
      current = ordered.last;
    }
    return ordered;
  }

  double _dist(LatLng a, LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return dlat * dlat + dlng * dlng;
  }

  Future<void> _buildRoute() async {
    // Collect waypoints: SOS alerts + top 3 high-risk zones
    final alertPoints = widget.alerts
        .where((a) => a.lat != null && a.lng != null)
        .map((a) => LatLng(a.lat!, a.lng!))
        .toList();

    final highRiskZones = Zone.chennaiZones
        .where((z) => z.riskLevel == 'HIGH')
        .take(3)
        .map((z) => LatLng(z.lat, z.lng))
        .toList();

    final allTargets = [...alertPoints, ...highRiskZones];
    if (allTargets.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final ordered = _greedyOrder(widget.officerPos, allTargets);

    // Build stops list
    final stops = <Map<String, dynamic>>[];
    for (int i = 0; i < ordered.length; i++) {
      final pt = ordered[i];
      // Find matching alert or zone
      final alert = widget.alerts.firstWhere(
        (a) => a.lat != null && (a.lat! - pt.latitude).abs() < 0.001,
        orElse: () => SosAlert(id: '', zoneName: '', riskLevel: '', timestamp: DateTime.now(), status: ''),
      );
      final zone = Zone.chennaiZones.firstWhere(
        (z) => (z.lat - pt.latitude).abs() < 0.001,
        orElse: () => const Zone(pincode: '', name: 'Unknown', riskLevel: 'LOW', lat: 0, lng: 0),
      );
      final name = alert.zoneName.isNotEmpty ? alert.zoneName : zone.name;
      final risk = alert.riskLevel.isNotEmpty ? alert.riskLevel : zone.riskLevel;
      stops.add({'name': name, 'risk': risk, 'eta': '${(i + 1) * 4} min', 'point': pt});
    }

    // Fetch OSRM route
    final allPoints = [widget.officerPos, ...ordered];
    final coords = allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = 'http://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';

    List<LatLng> routePoints = allPoints;
    double totalKm = 0;

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        routePoints = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        final distM = (data['routes'][0]['distance'] as num).toDouble();
        final durS  = (data['routes'][0]['duration'] as num).toDouble();
        totalKm = distM / 1000;
        final eta = DateTime.now().add(Duration(seconds: durS.toInt()));
        _eta = '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _routePoints = routePoints;
        _stops = stops;
        _totalDist = totalKm > 0 ? '${totalKm.toStringAsFixed(1)} KM' : '${(stops.length * 1.8).toStringAsFixed(1)} KM';
        if (_eta == '—') {
          final eta = DateTime.now().add(Duration(minutes: stops.length * 5));
          _eta = '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
        }
        _loading = false;
      });
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFef4444);
      case 'MEDIUM': return const Color(0xFFf59e0b);
      default:       return const Color(0xFF22c55e);
    }
  }

  Future<void> _startNavigation() async {
    if (_backendMapsUrl != null && _backendMapsUrl!.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(_backendMapsUrl!), mode: LaunchMode.externalApplication);
        return;
      } catch (_) {}
    }
    if (_stops.isEmpty) return;
    final waypoints = _stops
        .map((s) => (s['point'] as LatLng))
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');
    final dest = _stops.last['point'] as LatLng;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${dest.latitude},${dest.longitude}'
      '&waypoints=$waypoints',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPri,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optimised Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Sector ${_stops.length} stops', style: const TextStyle(fontSize: 11, color: _textMut)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22c55e).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF22c55e).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.gps_fixed, color: Color(0xFF22c55e), size: 12),
                SizedBox(width: 4),
                Text('GPS LOCKED', style: TextStyle(color: Color(0xFF22c55e), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00d4b4)))
          : Column(
              children: [
                // Destination area (backend)
                if (_backendArea != null)
                  Container(
                    color: _surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: _teal, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Destination: $_backendArea',
                          style: const TextStyle(color: _textMut, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // Distance + ETA bar
                Container(
                  color: _surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.route, color: _teal, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_backendDistKm != null ? '${_backendDistKm!.toStringAsFixed(1)} KM' : _totalDist} TOTAL  ·  '
                        '${_backendEtaMins != null ? '$_backendEtaMins MIN ETA' : '$_eta ETA'}',
                        style: const TextStyle(
                          color: _textPri,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Map
                SizedBox(
                  height: 260,
                  child: FutureBuilder<List<Polygon>>(
                    future: _kmlZonesFuture,
                    builder: (context, snapshot) {
                      return FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.officerPos,
                          initialZoom: 11,
                          backgroundColor: _bg,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
                            userAgentPackageName: 'com.rakshak.app',
                          ),
                          // KML zone polygons (risk-coloured)
                          if (snapshot.hasData)
                            PolygonLayer(polygons: snapshot.data!),
                          if (_routePoints.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  color: const Color(0xFFf59e0b),
                                  strokeWidth: 3,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.officerPos,
                                width: 32, height: 32,
                                child: const Icon(Icons.person_pin_circle, color: Color(0xFF3b82f6), size: 28),
                              ),
                              ..._stops.map((s) {
                                final pt = s['point'] as LatLng;
                                final color = _riskColor(s['risk'] as String);
                                return Marker(
                                  point: pt,
                                  width: 28, height: 28,
                                  child: Icon(Icons.location_on, color: color, size: 24),
                                );
                              }),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Patrol sequence
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stops.length,
                    itemBuilder: (_, i) {
                      final stop = _stops[i];
                      final color = _riskColor(stop['risk'] as String);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: color),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(stop['name'] as String, style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600)),
                                  Text('ETA: ${stop['eta']}', style: const TextStyle(color: _textMut, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stop['risk'] as String,
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Deployment zones from patrol optimizer
                if (_optimizerLoading || _deploymentZones.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _teal.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: _teal, size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                'AI DEPLOYMENT SUGGESTIONS',
                                style: TextStyle(
                                  color: _teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              if (_optimizerLoading)
                                const SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: _teal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_deploymentZones.isEmpty && !_optimizerLoading)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Text(
                              'No suggestions available',
                              style: TextStyle(color: _textMut, fontSize: 12),
                            ),
                          ),
                        ..._deploymentZones.map((zone) {
                          final name     = zone['name']?.toString()
                              ?? zone['zone_name']?.toString()
                              ?? zone['pincode']?.toString()
                              ?? 'Zone';
                          final priority = zone['priority']?.toString()
                              ?? zone['risk_level']?.toString()
                              ?? zone['risk']?.toString()
                              ?? '';
                          final reason   = zone['reason']?.toString()
                              ?? zone['rationale']?.toString()
                              ?? '';
                          final color    = _riskColor(priority);
                          return Container(
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.place, color: color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: _textPri,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (reason.isNotEmpty)
                                        Text(
                                          reason,
                                          style: const TextStyle(color: _textMut, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                if (priority.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      priority.toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                // Start navigation button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: const Color(0xFF00382e),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        'START NAVIGATION',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  static const _bg      = Color(0xFF0d1117);
  static const _surface = Color(0xFF161b22);
  static const _red     = Color(0xFFef4444);
  static const _amber   = Color(0xFFf59e0b);
  static const _green   = Color(0xFF22c55e);
  static const _textPri = Color(0xFFf0f6fc);
  static const _textMut = Color(0xFF8b949e);

  bool _loading = true;
  int _totalCount = 0;
  List<Map<String, dynamic>> _byPincode = [];

  // Fleet stats — updated from /patrols
  int _activePatrols = 0;
  int _responseUnits = 0;
  int _standby       = 0;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Poll both citizens + patrols every 60 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    final citizensData = await ApiService.fetchCitizensActive();
    final patrols      = await ApiService.fetchPatrols();

    if (!mounted) return;
    setState(() {
      _totalCount = (citizensData['total_count'] as num?)?.toInt() ?? 0;
      final raw = citizensData['by_pincode'] as List<dynamic>? ?? [];
      _byPincode = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _loading = false;

      // Fleet stats from live /patrols
      if (patrols.isNotEmpty) {
        _activePatrols = patrols
            .where((p) =>
                p.status.toLowerCase() == 'patrolling' ||
                p.status.toLowerCase() == 'active')
            .length;
        _responseUnits = patrols
            .where((p) => p.status.toLowerCase() == 'responding')
            .length;
        _standby = patrols
            .where((p) => p.status.toLowerCase() == 'standby')
            .length;
        // If all zeros (unknown status strings), use total as active
        if (_activePatrols == 0 && _responseUnits == 0 && _standby == 0) {
          _activePatrols = patrols.length;
        }
      }
    });
  }

  Color _riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':   return _red;
      case 'MEDIUM': return _amber;
      default:       return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    if (hour < 22) {
      return const ColoredBox(
        color: _bg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bedtime_outlined, color: Color(0xFF8b949e), size: 48),
              SizedBox(height: 16),
              Text(
                'Monitor Active After 10 PM',
                style: TextStyle(
                    color: Color(0xFFf0f6fc),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Unresolved journey tracking begins at 22:00',
                style: TextStyle(color: _textMut, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const ColoredBox(
        color: _bg,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00d4b4)),
        ),
      );
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} PM';
    final displayTotal = _totalCount > 0
        ? _totalCount
        : _byPincode.fold<int>(
            0, (sum, z) => sum + ((z['count'] as num?)?.toInt() ?? 0));

    return Container(
      color: _bg,
      child: Column(
        children: [
          // Header
          Container(
            color: _surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unresolved Journeys',
                        style: TextStyle(
                            color: Color(0xFFf0f6fc),
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(timeStr,
                          style: const TextStyle(
                              color: Color(0xFF8b949e), fontSize: 12)),
                    ],
                  ),
                ),
                // Refresh button
                GestureDetector(
                  onTap: _fetch,
                  child: const Icon(Icons.refresh,
                      color: Color(0xFF00d4b4), size: 18),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _red.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '$displayTotal total',
                    style: const TextStyle(
                        color: _red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Pincode list
          Expanded(
            child: _byPincode.isEmpty
                ? const Center(
                    child: Text(
                      'No active citizens tracked',
                      style: TextStyle(color: _textMut, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _byPincode.length,
                    itemBuilder: (_, i) {
                      final z = _byPincode[i];
                      final risk =
                          (z['risk'] as String? ?? 'LOW').toUpperCase();
                      final color = _riskColor(risk);
                      final area = z['area'] as String? ??
                          z['pincode']?.toString() ??
                          '—';
                      final pincode = z['pincode']?.toString() ?? '';
                      final count = (z['count'] as num?)?.toInt() ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                              left: BorderSide(color: color, width: 3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(area,
                                      style: const TextStyle(
                                          color: _textPri,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  if (pincode.isNotEmpty)
                                    Text(pincode,
                                        style: const TextStyle(
                                            color: _textMut, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('$count',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.5)),
                              ),
                              child: Text(risk,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Fleet status footer — live from /patrols
          Container(
            color: _surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _fleetStat('Active Patrols',
                    _activePatrols > 0 ? '$_activePatrols' : '—',
                    _green),
                _fleetStat('Responding',
                    _responseUnits > 0 ? '$_responseUnits' : '—',
                    _amber),
                _fleetStat('Standby',
                    _standby > 0 ? '$_standby' : '—',
                    _textMut),
              ],
            ),
          ),

          // Alert button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert sent to all units'),
                      backgroundColor: Color(0xFF161b22),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.campaign, size: 20),
                label: const Text(
                  'INITIATE AREA-WIDE ALERT',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fleetStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label,
            style:
                const TextStyle(color: Color(0xFF8b949e), fontSize: 10)),
      ],
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_alert.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

// ── Nominatim pincode boundary fetcher ───────────────────────────────────────
// Fetches polygon boundaries from OSM Nominatim — no file assets needed.

Future<List<Polygon>> fetchPincodePolygon(String pincode, String risk) async {
  try {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$pincode,Chennai,Tamil+Nadu,India'
      '&format=geojson&polygon_geojson=1&limit=1',
    );
    final res = await http
        .get(url, headers: {'User-Agent': 'Rakshak/1.0'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];

    final geo      = jsonDecode(res.body) as Map<String, dynamic>;
    final features = geo['features'] as List<dynamic>;
    if (features.isEmpty) return [];

    final fillColor = risk == 'HIGH'
        ? const Color(0xFFef4444).withValues(alpha: 0.40)
        : risk == 'MEDIUM'
            ? const Color(0xFFf59e0b).withValues(alpha: 0.35)
            : const Color(0xFF22c55e).withValues(alpha: 0.25);

    final borderColor = risk == 'HIGH'
        ? const Color(0xFFef4444)
        : risk == 'MEDIUM'
            ? const Color(0xFFf59e0b)
            : const Color(0xFF22c55e);

    final polygons = <Polygon>[];
    final geom     = features[0]['geometry'] as Map<String, dynamic>;
    final type     = geom['type'] as String;
    final coords   = geom['coordinates'] as List<dynamic>;

    final rings = <List<dynamic>>[];
    if (type == 'Polygon') {
      rings.add(coords[0] as List<dynamic>);
    } else if (type == 'MultiPolygon') {
      for (final p in coords) {
        rings.add((p as List<dynamic>)[0] as List<dynamic>);
      }
    }

    for (final ring in rings) {
      final points = ring.map((c) {
        final coord = c as List<dynamic>;
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();
      if (points.length >= 3) {
        polygons.add(Polygon(
          points:            points,
          color:             fillColor,
          borderColor:       borderColor,
          borderStrokeWidth: 1.5,
          isFilled:          true,
        ));
      }
    }
    return polygons;
  } catch (_) {
    return [];
  }
}

// ── MapScreen ─────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  final String officerBadge;
  final String officerName;

  const MapScreen({
    super.key,
    required this.officerBadge,
    required this.officerName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _bg      = Color(0xFF0d1117);
  static const _surface = Color(0xFF161b22);
  static const _teal    = Color(0xFF00d4b4);
  static const _red     = Color(0xFFef4444);
  static const _textPri = Color(0xFFf0f6fc);
  static const _textMut = Color(0xFF8b949e);

  // Zone risk — seeded with defaults, updated every 60s from /score/refresh
  Map<String, String> _zoneRisk = {
    '600017': 'HIGH',
    '600081': 'HIGH',
    '600006': 'MEDIUM',
    '600004': 'MEDIUM',
    '600058': 'LOW',
  };

  // Cached polygon ring geometry per pincode (avoids re-fetching Nominatim)
  final Map<String, List<List<LatLng>>> _polygonRings = {};

  int _tab = 0;
  LatLng _officerPos = const LatLng(13.0827, 80.2707);
  List<SosAlert> _alerts    = [];
  List<Polygon>  _kmlPolygons = [];
  bool _zonesLoading = true;
  Timer? _pollTimer;
  Timer? _riskTimer;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  final MapController _mapController = MapController();

  // ── Active incident — set when officer accepts a SOS ─────────────────────
  SosAlert? _activeIncident;
  bool _accepting = false;   // true while PATCH is in-flight

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    _initLocation();
    _loadZones();
    _pollSos();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollSos());
    // Refresh zone risk scores every 60 seconds from /score/refresh
    _riskTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshRisk());
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _officerPos = pos);
  }

  Future<void> _loadZones() async {
    final all = <Polygon>[];
    for (final entry in _zoneRisk.entries) {
      final polys = await fetchPincodePolygon(entry.key, entry.value);
      all.addAll(polys);
      // Cache ring geometry so we can recolor without re-fetching Nominatim
      _polygonRings[entry.key] = polys.map((p) => p.points).toList();
      // Nominatim rate limit: 1 req/sec
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (mounted) setState(() { _kmlPolygons = all; _zonesLoading = false; });
  }

  /// Poll /score/refresh every 60s and recolor zones if risk levels change.
  Future<void> _refreshRisk() async {
    final zones = _zoneRisk.keys.map((code) => {
      'pincode': code,
      'hour': DateTime.now().hour,
      'day_of_week': DateTime.now().weekday % 7,
    }).toList();

    final result = await ApiService.refreshScores(zones);
    if (result.isEmpty || !mounted) return;

    final raw = result['results'] ?? result['zones'] ?? result;
    if (raw is! List) return;

    bool changed = false;
    for (final r in raw) {
      final code  = r['pincode']?.toString() ?? '';
      final level = (r['risk_level'] ?? r['riskLevel'])?.toString().toUpperCase() ?? '';
      if (code.isNotEmpty && level.isNotEmpty && _zoneRisk[code] != level) {
        _zoneRisk[code] = level;
        changed = true;
      }
    }

    if (changed) _rebuildPolygons();
  }

  /// Rebuild Polygon objects from cached ring geometry with updated risk colors.
  void _rebuildPolygons() {
    final all = <Polygon>[];
    for (final entry in _polygonRings.entries) {
      final risk        = _zoneRisk[entry.key] ?? 'LOW';
      final fillColor   = risk == 'HIGH'
          ? const Color(0xFFef4444).withValues(alpha: 0.40)
          : risk == 'MEDIUM'
              ? const Color(0xFFf59e0b).withValues(alpha: 0.35)
              : const Color(0xFF22c55e).withValues(alpha: 0.25);
      final borderColor = risk == 'HIGH'
          ? const Color(0xFFef4444)
          : risk == 'MEDIUM'
              ? const Color(0xFFf59e0b)
              : const Color(0xFF22c55e);
      for (final points in entry.value) {
        if (points.length >= 3) {
          all.add(Polygon(
            points:            points,
            color:             fillColor,
            borderColor:       borderColor,
            borderStrokeWidth: 1.5,
            isFilled:          true,
          ));
        }
      }
    }
    if (mounted) setState(() => _kmlPolygons = all);
  }

  // ── SOS deduplication — same pattern as dashboard useSosEvents ──────────
  final Set<String> _seenSosIds = {};

  Future<void> _pollSos() async {
    // Use GET /sos/live — same endpoint as the dashboard
    final fresh = await ApiService.fetchLiveSos();
    if (!mounted) return;

    // Merge: add new IDs, keep existing accepted incident intact
    final merged = <SosAlert>[];
    for (final alert in fresh) {
      final id = alert.sosId ?? alert.id;
      _seenSosIds.add(id);
      merged.add(alert);
    }

    setState(() => _alerts = merged);
  }

  /// Accept a SOS — PATCH backend, set as active incident, switch to map tab.
  Future<void> _acceptSos(SosAlert alert) async {
    if (_accepting) return;
    setState(() => _accepting = true);

    final sosId = alert.sosId ?? alert.id;
    if (sosId.isNotEmpty) {
      await ApiService.acceptSos(sosId);
    }

    if (mounted) {
      setState(() {
        _activeIncident = alert;
        _accepting = false;
        _tab = 0;   // switch to MAP tab to show route
      });
      // Pan map to SOS location
      if (alert.lat != null && alert.lng != null) {
        _mapController.move(LatLng(alert.lat!, alert.lng!), 14.0);
      }
    }
  }

  /// Open Google Maps navigation to the SOS location using lat/lng from the record.
  /// Falls back to pincode search if coordinates are unavailable.
  Future<void> _navigateToSos(SosAlert incident) async {
    final lat = incident.lat;
    final lng = incident.lng;
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    } else {
      final pincode = incident.pincode ?? '';
      uri = Uri.parse(
          'https://www.google.com/maps/search/${Uri.encodeComponent('$pincode Chennai India')}');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _riskTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Zoom button ───────────────────────────────────────────────────────────
  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1c2128),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  Widget _buildMap() {
    final incident = _activeIncident;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(13.0827, 80.2707),
            initialZoom: 11.0,
            minZoom: 9.0,
            maxZoom: 16.0,
            backgroundColor: Color(0xFF0d1117),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.rakshak.police',
            ),
            // Zone polygons
            if (_kmlPolygons.isNotEmpty)
              PolygonLayer(polygons: _kmlPolygons),
            // Active incident marker only — no simulated patrol dots
            if (incident != null && incident.lat != null && incident.lng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(incident.lat!, incident.lng!),
                    width: 48, height: 48,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _red.withValues(alpha: _pulseAnim.value * 0.35),
                          border: Border.all(color: _red, width: 2.5),
                        ),
                        child: const Icon(Icons.sos, color: _red, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            // Officer position
            MarkerLayer(
              markers: [
                Marker(
                  point: _officerPos,
                  width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3b82f6).withValues(alpha: 0.2),
                      border: Border.all(color: const Color(0xFF3b82f6), width: 2),
                    ),
                    child: const Icon(Icons.person_pin_circle,
                        color: Color(0xFF3b82f6), size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Zoom buttons
        Positioned(
          bottom: 100, right: 12,
          child: Column(
            children: [
              _zoomBtn(Icons.add, () => _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              )),
              const SizedBox(height: 4),
              _zoomBtn(Icons.remove, () => _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              )),
            ],
          ),
        ),

        // Active incident banner
        if (incident != null)
          Positioned(
            top: 12, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sos, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RESPONDING TO: ${incident.zoneName}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _activeIncident = null),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),
          ),

        // No active incident — empty state
        if (incident == null && _alerts.isEmpty && !_zonesLoading)
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'No active incidents right now.',
                  style: TextStyle(color: _textMut, fontSize: 12),
                ),
              ),
            ),
          ),

        // Route button — only when incident is active
        if (incident != null)
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToSos(incident),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: const Color(0xFF00382e),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('NAVIGATE TO SOS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),

        // Loading zones indicator
        if (_zonesLoading)
          Positioned(
            top: incident != null ? 70 : 12, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10, height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Color(0xFF00d4b4)),
                    ),
                    SizedBox(width: 6),
                    Text('Loading zones…',
                        style: TextStyle(color: Color(0xFF8b949e), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF22c55e), size: 48),
            SizedBox(height: 12),
            Text('No active incidents right now.',
                style: TextStyle(color: Color(0xFF8b949e), fontSize: 14)),
            SizedBox(height: 6),
            Text('Live SOS alerts will appear here.',
                style: TextStyle(color: Color(0xFF8b949e), fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (_, i) {
        final a = _alerts[i];
        final isActive = _activeIncident?.id == a.id;
        final timeAgo  = _timeAgo(a.timestamp);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: isActive ? _teal : _red,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone + risk badge
                Row(
                  children: [
                    Icon(Icons.sos, color: isActive ? _teal : _red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.zoneName,
                          style: const TextStyle(
                              color: _textPri,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(a.riskLevel,
                          style: const TextStyle(
                              color: _red, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Pincode + time
                Row(
                  children: [
                    if (a.pincode != null) ...[
                      const Icon(Icons.location_on_outlined, color: _textMut, size: 13),
                      const SizedBox(width: 3),
                      Text(a.pincode!, style: const TextStyle(color: _textMut, fontSize: 11)),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.access_time, color: _textMut, size: 13),
                    const SizedBox(width: 3),
                    Text(timeAgo, style: const TextStyle(color: _textMut, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                // Accept / Active button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: isActive
                      ? OutlinedButton.icon(
                          onPressed: () => setState(() => _tab = 0),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _teal,
                            side: const BorderSide(color: _teal),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('VIEW ON MAP',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        )
                      : ElevatedButton.icon(
                          onPressed: _accepting ? null : () => _acceptSos(a),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          icon: _accepting
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check, size: 16),
                          label: Text(_accepting ? 'Accepting…' : 'ACCEPT & RESPOND',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                ),

                // ── Cancelled SOS banner — shows phone for follow-up ──
                if (a.status == 'cancelled')
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.amber, size: 16),
                            SizedBox(width: 6),
                            Text('SOS Cancelled by user',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                        if (a.userPhone != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse('tel:${a.userPhone}'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Call to verify: ${a.userPhone}',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.greenAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          const Text('No phone number on record.',
                              style: TextStyle(color: Colors.amber, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _activeIncident != null;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Container(
              color: _surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: _teal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.officerName,
                            style: const TextStyle(
                                color: _textPri,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(widget.officerBadge,
                            style: const TextStyle(
                                color: _textMut,
                                fontSize: 11,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22c55e).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF22c55e).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF22c55e), size: 8),
                        SizedBox(width: 4),
                        Text('ON DUTY',
                            style: TextStyle(
                                color: Color(0xFF22c55e),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _buildMap(),
                  _buildAlertsTab(),
                  _buildResponseTab(),
                ],
              ),
            ),

            // ── Bottom nav ───────────────────────────────────────────────
            Container(
              color: _surface,
              child: Row(
                children: [
                  _navItem(0, Icons.map_outlined, 'MAP'),
                  _navItem(1, Icons.warning_amber_outlined, 'ALERTS',
                      badge: _alerts.isNotEmpty ? _alerts.length.toString() : null),
                  _navItem(2, Icons.bolt_outlined, 'RESPONSE',
                      badge: hasActive ? '1' : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pincode coordinate lookup (Chennai zones) ────────────────────────────
  static const Map<String, List<double>> _pincodeCoords = {
    '600001': [13.0827, 80.2707], '600004': [13.0732, 80.2609],
    '600005': [13.0569, 80.2787], '600006': [13.0715, 80.2740],
    '600007': [13.1127, 80.2966], '600008': [13.1186, 80.2487],
    '600009': [13.1483, 80.2355], '600010': [13.1675, 80.2617],
    '600014': [13.0339, 80.2553], '600015': [13.0339, 80.2707],
    '600017': [13.0067, 80.2570], '600018': [13.0521, 80.2193],
    '600019': [13.0475, 80.2030], '600020': [13.0521, 80.2118],
    '600024': [12.9815, 80.2209], '600028': [12.9995, 80.2666],
    '600029': [12.9845, 80.2657], '600032': [13.0350, 80.2323],
    '600034': [13.0339, 80.2193], '600035': [13.0402, 80.2091],
    '600036': [13.0883, 80.2105], '600040': [13.0850, 80.2101],
    '600042': [13.0883, 80.1762], '600044': [13.0339, 80.1575],
    '600045': [13.0237, 80.1762], '600050': [12.9673, 80.1501],
    '600053': [12.9515, 80.1438], '600056': [12.9625, 80.2387],
    '600061': [12.9000, 80.2277], '600064': [12.9240, 80.1958],
    '600073': [12.9150, 80.1501], '600078': [13.1144, 80.1606],
    '600082': [13.1675, 80.2355], '600083': [13.1483, 80.2355],
    '600099': [13.1186, 80.2091], '600118': [12.9065, 80.1958],
  };

  /// Returns the [count] pincodes nearest to [pos], sorted by distance.
  List<String> _nearestPincodes(LatLng pos, {int count = 2}) {
    final entries = _pincodeCoords.entries.toList()
      ..sort((a, b) {
        final da = _sqDist(pos.latitude, pos.longitude, a.value[0], a.value[1]);
        final db = _sqDist(pos.latitude, pos.longitude, b.value[0], b.value[1]);
        return da.compareTo(db);
      });
    return entries.take(count).map((e) => e.key).toList();
  }

  double _sqDist(double lat1, double lng1, double lat2, double lng2) {
    final dlat = lat1 - lat2;
    final dlng = lng1 - lng2;
    return dlat * dlat + dlng * dlng;
  }

  Widget _buildResponseTab() {
    final incident  = _activeIncident;
    // When an incident is active, use its pincode as the current zone.
    // Otherwise fall back to GPS-derived nearest pincode.
    final nearest   = _nearestPincodes(_officerPos, count: 2);
    // Only show a pincode when an SOS is actively accepted; otherwise show "—"
    final curPin    = incident?.pincode ?? '—';
    final nearbyPin = nearest.isNotEmpty ? nearest[0] : '—';
    final curRisk   = _zoneRisk[curPin] ?? 'UNKNOWN';
    final activeSos = _alerts.where((a) => a.status != 'resolved').length;

    final riskColor = curRisk == 'HIGH'
        ? _red
        : curRisk == 'MEDIUM'
            ? const Color(0xFFf59e0b)
            : const Color(0xFF22c55e);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Operational status card ───────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OPERATIONAL STATUS',
                    style: TextStyle(
                        color: _textMut, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 14),

                // Current pincode
                _statusRow(
                  label: 'Current pincode',
                  value: curPin,
                  valueColor: incident != null ? _teal : _textMut,
                  icon: Icons.location_on_outlined,
                  sub: incident == null ? 'No active incident' : null,
                  subColor: _textMut,
                ),
                const Divider(color: Colors.white12, height: 20),

                // Nearby pincode
                _statusRow(
                  label: 'Nearby pincode',
                  value: nearbyPin,
                  valueColor: _textPri,
                  icon: Icons.near_me_outlined,
                  sub: _zoneRisk[nearbyPin] != null
                      ? 'Risk: ${_zoneRisk[nearbyPin]}'
                      : null,
                  subColor: _zoneRisk[nearbyPin] == 'HIGH'
                      ? _red
                      : _zoneRisk[nearbyPin] == 'MEDIUM'
                          ? const Color(0xFFf59e0b)
                          : _textMut,
                ),
                const Divider(color: Colors.white12, height: 20),

                // Active SOS count
                _statusRow(
                  label: 'Active SOS',
                  value: activeSos == 0 ? 'None' : '$activeSos',
                  valueColor: activeSos > 0 ? _red : const Color(0xFF22c55e),
                  icon: Icons.sos_outlined,
                  sub: activeSos > 0 ? 'Tap Alerts to respond' : null,
                  subColor: _textMut,
                ),
                const Divider(color: Colors.white12, height: 20),

                // Last accepted SOS
                _statusRow(
                  label: 'Last accepted SOS',
                  value: incident != null
                      ? incident.zoneName
                      : 'None',
                  valueColor: incident != null ? _teal : _textMut,
                  icon: Icons.check_circle_outline,
                  sub: incident != null ? 'Dispatched · ${incident.pincode ?? ""}' : null,
                  subColor: _textMut,
                ),
              ],
            ),
          ),

          // ── Zone risk summary ─────────────────────────────────────────
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('CURRENT ZONE RISK',
                        style: TextStyle(
                            color: _textMut, fontSize: 10,
                            fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(curRisk,
                          style: TextStyle(
                              color: riskColor, fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(curPin,
                    style: const TextStyle(
                        color: _textPri, fontSize: 22,
                        fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text('${_zoneRisk.values.where((v) => v == 'HIGH').length} HIGH · '
                    '${_zoneRisk.values.where((v) => v == 'MEDIUM').length} MEDIUM · '
                    '${_zoneRisk.values.where((v) => v == 'LOW').length} LOW',
                    style: const TextStyle(color: _textMut, fontSize: 11)),
              ],
            ),
          ),

          // ── Active incident action ────────────────────────────────────
          if (incident != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSos(incident),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: const Color(0xFF00382e),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('NAVIGATE TO SOS',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => setState(() => _activeIncident = null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textMut,
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('MARK RESOLVED',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],

          // ── Empty state ───────────────────────────────────────────────
          if (incident == null && activeSos == 0) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.shield_outlined,
                      color: _textMut.withValues(alpha: 0.4), size: 36),
                  const SizedBox(height: 8),
                  const Text('No active incidents.',
                      style: TextStyle(color: _textMut, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Accept a SOS from Alerts to respond.',
                      style: TextStyle(color: _textMut, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    String? sub,
    Color? subColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: _textMut, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: _textMut, fontSize: 11)),
              if (sub != null)
                Text(sub,
                    style: TextStyle(
                        color: subColor ?? _textMut, fontSize: 10)),
            ],
          ),
        ),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace')),
      ],
    );
  }

  Widget _navItem(int index, IconData icon, String label, {String? badge}) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: active ? _teal : _textMut, size: 22),
                  if (badge != null)
                    Positioned(
                      top: -4, right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: _red, shape: BoxShape.circle),
                        child: Text(badge,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: active ? _teal : _textMut,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _badgeCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  static const _bg       = Color(0xFF0d1117);
  static const _surface  = Color(0xFF161b22);
  static const _border   = Color(0xFF30363d);
  static const _teal     = Color(0xFF00d4b4);
  static const _textPri  = Color(0xFFf0f6fc);
  static const _textMut  = Color(0xFF8b949e);

  void _login() async {
    if (_badgeCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter badge number and secure key')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          officerBadge: _badgeCtrl.text,
          officerName: 'Officer ${_badgeCtrl.text.split('-').last}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // ── Shield logo ──────────────────────────────────────────────
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF242c29),
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(Icons.shield, color: _teal, size: 40),
                  ),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bg, width: 3),
                    ),
                    child: const Icon(Icons.verified_user, color: Color(0xFF00382e), size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Title ────────────────────────────────────────────────────
              const Text(
                'RAKSHAK',
                style: TextStyle(
                  color: _textPri,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 32, height: 1, color: _border),
                  const SizedBox(width: 8),
                  const Text(
                    'TAMIL NADU POLICE',
                    style: TextStyle(
                      color: _teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 32, height: 1, color: _border),
                ],
              ),
              const SizedBox(height: 32),

              // ── Login card ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Officer Authentication',
                      style: TextStyle(
                        color: _textPri,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Secure access for authorized personnel only.',
                      style: TextStyle(color: _textMut, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Username field
                    const Text(
                      'USERNAME',
                      style: TextStyle(
                        color: _textMut,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _badgeCtrl,
                      hint: 'TN-XXXX-XXXX',
                      icon: Icons.person_outline,
                      obscure: false,
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SECURE KEY',
                          style: TextStyle(
                            color: _textMut,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'RECOVER',
                          style: TextStyle(
                            color: _teal.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _passwordCtrl,
                      hint: '••••••••',
                      icon: Icons.vpn_key_outlined,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: _textMut,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // GO ON DUTY button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: const Color(0xFF00382e),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00382e),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'GO ON DUTY',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Biometric
                    Center(
                      child: TextButton.icon(
                        onPressed: _login,
                        icon: const Icon(Icons.fingerprint, color: _textMut, size: 20),
                        label: const Text(
                          'BIOMETRIC LOGIN',
                          style: TextStyle(
                            color: _textMut,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, color: _textMut, size: 14),
                  const SizedBox(width: 4),
                  const Text('CHENNAI HQ', style: TextStyle(color: _textMut, fontSize: 11)),
                  const SizedBox(width: 20),
                  const Icon(Icons.security, color: _textMut, size: 14),
                  const SizedBox(width: 4),
                  const Text('AES-256', style: TextStyle(color: _textMut, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: _textPri, fontSize: 14, fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMut.withValues(alpha: 0.5), fontFamily: 'monospace'),
          prefixIcon: Icon(icon, color: _textMut, size: 18),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;
import '../models/sos_alert.dart';
import '../services/api_service.dart';

class SosDetailScreen extends StatelessWidget {
  final SosAlert alert;

  const SosDetailScreen({super.key, required this.alert});

  static const _bg      = Color(0xFF0d1117);
  static const _surface = Color(0xFF161b22);
  static const _border  = Color(0xFF30363d);
  static const _red     = Color(0xFFef4444);
  static const _yellow  = Color(0xFFf59e0b);
  static const _textPri = Color(0xFFf0f6fc);
  static const _textMut = Color(0xFF8b949e);

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    return '${diff.inHours} hours ago';
  }

  Future<void> _navigateTo(BuildContext context) async {
    final lat = alert.lat ?? 13.0827;
    final lng = alert.lng ?? 80.2707;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps')),
        );
      }
    }
  }

  Future<void> _closeAlert(BuildContext context) async {
    if (alert.sosId != null) {
      await ApiService.resolveSos(alert.sosId!);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Banner — yellow for cancelled, red for active
            if (alert.status == 'cancelled') ...[
              Container(
                width: double.infinity,
                color: _yellow,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.black, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '⚠️ SOS Cancelled by user',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    if (alert.userPhone != null && alert.userPhone!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('tel:${alert.userPhone}'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.black87, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              '📞 Call to verify: ${alert.userPhone}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                color: _red,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'CRITICAL ALERT ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Alert info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.zoneName,
                                style: const TextStyle(
                                  color: _textPri,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _red.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                alert.riskLevel,
                                style: const TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow(Icons.confirmation_number_outlined, 'Alert ID', alert.id.length > 12 ? alert.id.substring(0, 12) : alert.id),
                        _infoRow(Icons.location_on_outlined, 'Location', '${alert.lat?.toStringAsFixed(4) ?? '13.0827'}°N, ${alert.lng?.toStringAsFixed(4) ?? '80.2707'}°E'),
                        _infoRow(Icons.access_time, 'Received', _timeAgo()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 24),

                  // Navigate button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateTo(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text(
                        'NAVIGATE THERE',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Close alert button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _closeAlert(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMut,
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'CLOSE ALERT',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: _textMut, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: _textMut, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _textPri, fontSize: 13, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SystemChrome APIs are mobile-only — skip on web to avoid silent crash
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  runApp(const RakshakPoliceApp());
}

// ── Phone frame — centers a 390×844 phone shell on web ───────────────────────
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 390,
          height: 844,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: child,
        ),
      ),
    );
  }
}

class RakshakPoliceApp extends StatelessWidget {
  const RakshakPoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0d1117),
      colorScheme: const ColorScheme.dark(
        primary:   Color(0xFF00d4b4),
        secondary: Color(0xFF00d4b4),
        surface:   Color(0xFF161b22),
        error:     Color(0xFFef4444),
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161b22),
        foregroundColor: Color(0xFFf0f6fc),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFf0f6fc),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF161b22),
        contentTextStyle: TextStyle(color: Color(0xFFf0f6fc)),
      ),
      useMaterial3: true,
    );

    // On web: wrap in a phone frame so it looks like a real device
    // On mobile: run full-screen as normal
    if (kIsWeb) {
      return MaterialApp(
        title: 'Rakshak Police',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: PhoneFrame(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: const LoginScreen(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Rakshak Police',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const LoginScreen(),
    );
  }
}
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  runApp(const ProviderScope(child: RakshakCitizenApp()));
}

class RakshakCitizenApp extends StatelessWidget {
  const RakshakCitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rakshak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which zones have been marked as patrolled.
/// Key: zoneId, Value: timestamp when it was marked.
class PatrolManagerNotifier
    extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};

  /// Marks [zoneId] as patrolled at the current time.
  void markAsPatrolled(String zoneId) {
    state = {...state, zoneId: DateTime.now()};
  }

  /// Clears the patrolled status for [zoneId].
  void clearPatrol(String zoneId) {
    final updated = Map<String, DateTime>.from(state);
    updated.remove(zoneId);
    state = updated;
  }

  /// Clears all patrol records.
  void clearAll() {
    state = {};
  }
}

/// Provider exposed to the widget tree.
/// The widget layer uses `Map<String, dynamic>` via `containsKey` checks,
/// so we expose `Map<String, DateTime>` which satisfies that contract.
final patrolManagerProvider =
    NotifierProvider<PatrolManagerNotifier, Map<String, DateTime>>(
  PatrolManagerNotifier.new,
);
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zone_risk.dart';

/// Stub heatmap data — replace with real API calls when backend is ready.
final _stubZones = <ZoneRisk>[
  ZoneRisk(
    zoneId: '600001',
    locationName: "Park Town",
    latitude: 13.0827,
    longitude: 80.2707,
    assessment: RiskAssessment(
      riskLevel: 'Critical',
      confidence: 0.91,
      timestamp: DateTime.now(),
    ),
  ),
  ZoneRisk(
    zoneId: '600003',
    locationName: "Royapuram",
    latitude: 13.0732,
    longitude: 80.2609,
    assessment: RiskAssessment(
      riskLevel: 'High',
      confidence: 0.78,
      timestamp: DateTime.now(),
    ),
  ),
  ZoneRisk(
    zoneId: '600017',
    locationName: "T.Nagar",
    latitude: 13.0418,
    longitude: 80.2341,
    assessment: RiskAssessment(
      riskLevel: 'High',
      confidence: 0.82,
      timestamp: DateTime.now(),
    ),
  ),
  ZoneRisk(
    zoneId: '600011',
    locationName: "Perambur",
    latitude: 13.1143,
    longitude: 80.2329,
    assessment: RiskAssessment(
      riskLevel: 'Medium',
      confidence: 0.65,
      timestamp: DateTime.now(),
    ),
  ),
  ZoneRisk(
    zoneId: '600040',
    locationName: "Nanganallur",
    latitude: 13.0850,
    longitude: 80.2101,
    assessment: RiskAssessment(
      riskLevel: 'Medium',
      confidence: 0.58,
      timestamp: DateTime.now(),
    ),
  ),
  ZoneRisk(
    zoneId: '600020',
    locationName: "Saidapet",
    latitude: 13.0012,
    longitude: 80.2565,
    assessment: RiskAssessment(
      riskLevel: 'Low',
      confidence: 0.44,
      timestamp: DateTime.now(),
    ),
  ),
];

/// Notifier that holds the async list of [ZoneRisk] objects.
class HeatmapDataNotifier
    extends AsyncNotifier<List<ZoneRisk>> {
  DateTime? _lastUpdate;

  /// The timestamp of the most recent successful data load.
  DateTime? get lastUpdate => _lastUpdate;

  @override
  Future<List<ZoneRisk>> build() async {
    return _fetch();
  }

  Future<List<ZoneRisk>> _fetch() async {
    // TODO: replace with real API call to the predict endpoint
    await Future.delayed(const Duration(milliseconds: 600));
    _lastUpdate = DateTime.now();
    return _stubZones;
  }

  /// Triggers a manual refresh of the heatmap data.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Provider exposed to the widget tree.
final heatmapDataProvider =
    AsyncNotifierProvider<HeatmapDataNotifier, List<ZoneRisk>>(
  HeatmapDataNotifier.new,
);
import 'package:flutter/material.dart';

/// Risk assessment for a single geographic zone.
class RiskAssessment {
  /// Human-readable risk level: 'Low', 'Medium', 'High', 'Critical'.
  final String riskLevel;

  /// Confidence score in the range [0.0, 1.0].
  final double confidence;

  /// When this assessment was computed.
  final DateTime timestamp;

  const RiskAssessment({
    required this.riskLevel,
    required this.confidence,
    required this.timestamp,
  });

  /// Colour used for map circles and list tiles.
  Color get displayColor {
    switch (riskLevel) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      riskLevel:  json['risk_level'] as String? ?? 'Low',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp:  json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// A geographic zone with its current risk assessment.
class ZoneRisk {
  /// Unique identifier for this zone (e.g. pincode string or area slug).
  final String zoneId;

  /// Human-readable location name shown in the list.
  final String locationName;

  final double latitude;
  final double longitude;

  final RiskAssessment assessment;

  const ZoneRisk({
    required this.zoneId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.assessment,
  });

  /// Returns true when the risk level is 'High' or 'Critical'.
  bool get isHighRisk =>
      assessment.riskLevel == 'High' || assessment.riskLevel == 'Critical';

  factory ZoneRisk.fromJson(Map<String, dynamic> json) {
    return ZoneRisk(
      zoneId:       json['zone_id'] as String,
      locationName: json['location_name'] as String,
      latitude:     (json['latitude'] as num).toDouble(),
      longitude:    (json['longitude'] as num).toDouble(),
      assessment:   RiskAssessment.fromJson(
          json['assessment'] as Map<String, dynamic>),
    );
  }
}
/// Snapshot of time-derived feature flags used by the ML prediction model.
class TimeContext {
  final int hour;
  final int dayOfWeek; // 0 = Sunday … 6 = Saturday
  final int isWeekend; // 1 or 0
  final int isNight;   // 1 if hour >= 20 || hour < 6
  final int isEvening; // 1 if hour >= 17 && hour < 20
  final int isRushHour; // 1 if (8–10) or (17–19)

  const TimeContext({
    required this.hour,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isNight,
    required this.isEvening,
    required this.isRushHour,
  });

  /// Creates a [TimeContext] from the current wall-clock time.
  factory TimeContext.now() {
    final now = DateTime.now();
    final h   = now.hour;
    final dow = now.weekday % 7; // DateTime.weekday: 1=Mon…7=Sun → 0=Sun…6=Sat
    return TimeContext(
      hour:       h,
      dayOfWeek:  dow,
      isWeekend:  (dow == 0 || dow == 6) ? 1 : 0,
      isNight:    (h >= 20 || h < 6)     ? 1 : 0,
      isEvening:  (h >= 17 && h < 20)    ? 1 : 0,
      isRushHour: ((h >= 8 && h <= 10) || (h >= 17 && h <= 19)) ? 1 : 0,
    );
  }

  /// Creates a [TimeContext] for a specific hour (used by Judge Mode).
  factory TimeContext.forHour(int hour) {
    final now = DateTime.now();
    final dow = now.weekday % 7;
    return TimeContext(
      hour:       hour,
      dayOfWeek:  dow,
      isWeekend:  (dow == 0 || dow == 6) ? 1 : 0,
      isNight:    (hour >= 20 || hour < 6)     ? 1 : 0,
      isEvening:  (hour >= 17 && hour < 20)    ? 1 : 0,
      isRushHour: ((hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 19)) ? 1 : 0,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/providers/heatmap_data_provider.dart';
import '../widgets/police_heatmap_widget.dart';
import '../widgets/high_risk_area_list.dart';
import '../widgets/live_clock_widget.dart';

class PoliceDashboardScreen extends ConsumerWidget {
  const PoliceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapNotifier = ref.read(heatmapDataProvider.notifier);
    final lastUpdate = heatmapNotifier.lastUpdate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rakshak Police Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (lastUpdate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'Last updated: ${DateFormat('HH:mm:ss').format(lastUpdate)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(heatmapDataProvider.notifier).refresh();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;

          if (isWideScreen) {
            // Desktop layout: side-by-side
            return Row(
              children: [
                // Left panel: Clock and High-Risk List
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: LiveClockWidget(),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: HighRiskAreaList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right panel: Heatmap
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      child: PoliceHeatmapWidget(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile/Tablet layout: stacked
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LiveClockWidget(),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Card(
                      elevation: 4,
                      child: const PoliceHeatmapWidget(),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: HighRiskAreaList(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/zone_risk.dart';
import '../../../domain/providers/heatmap_data_provider.dart';
import '../../../domain/providers/patrol_manager_provider.dart';

class HighRiskAreaList extends ConsumerWidget {
  const HighRiskAreaList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapDataAsync = ref.watch(heatmapDataProvider);
    final patrolRecords = ref.watch(patrolManagerProvider);

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'High-Risk Areas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(heatmapDataProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: heatmapDataAsync.when(
              data: (zones) {
                // Filter high-risk zones
                final highRiskZones = zones.where((z) => z.isHighRisk).toList();

                // Sort by confidence (descending)
                highRiskZones.sort((a, b) =>
                    b.assessment.confidence.compareTo(a.assessment.confidence));

                if (highRiskZones.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.green),
                        SizedBox(height: 16),
                        Text('No high-risk areas detected'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: highRiskZones.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final zone = highRiskZones[index];
                    final isPatrolled = patrolRecords.containsKey(zone.zoneId);

                    return HighRiskAreaTile(
                      zone: zone,
                      isPatrolled: isPatrolled,
                      onMarkPatrolled: () {
                        ref
                            .read(patrolManagerProvider.notifier)
                            .markAsPatrolled(zone.zoneId);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HighRiskAreaTile extends StatelessWidget {
  final ZoneRisk zone;
  final bool isPatrolled;
  final VoidCallback onMarkPatrolled;

  const HighRiskAreaTile({
    super.key,
    required this.zone,
    required this.isPatrolled,
    required this.onMarkPatrolled,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: zone.assessment.displayColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPatrolled ? Icons.check_circle : Icons.location_on,
          color: isPatrolled ? Colors.green : zone.assessment.displayColor,
        ),
      ),
      title: Text(
        zone.locationName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: zone.assessment.displayColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  zone.assessment.riskLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(zone.assessment.confidence * 100).toStringAsFixed(0)}% confidence',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(zone.assessment.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: isPatrolled
          ? const Chip(
              label: Text('Patrolled', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            )
          : ElevatedButton.icon(
              onPressed: onMarkPatrolled,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Mark Patrolled'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/models/zone_risk.dart';
import '../../../domain/providers/heatmap_data_provider.dart';
import '../../../domain/providers/patrol_manager_provider.dart';
import '../../../shared/constants.dart';

class PoliceHeatmapWidget extends ConsumerWidget {
  const PoliceHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapDataAsync = ref.watch(heatmapDataProvider);
    final patrolRecords = ref.watch(patrolManagerProvider);

    return heatmapDataAsync.when(
      data: (zones) => _HeatmapMap(zones: zones, patrolRecords: patrolRecords),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading heatmap: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(heatmapDataProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapMap extends StatelessWidget {
  final List<ZoneRisk> zones;
  final Map<String, DateTime> patrolRecords;

  const _HeatmapMap({required this.zones, required this.patrolRecords});

  List<CircleMarker> _buildCircles() {
    return zones.map((zone) {
      double weight;
      switch (zone.assessment.riskLevel) {
        case 'High':
          weight = RiskConstants.highWeight;
          break;
        case 'Medium':
          weight = RiskConstants.mediumWeight;
          break;
        case 'Low':
          weight = RiskConstants.lowWeight;
          break;
        default:
          weight = 0.1;
      }

      return CircleMarker(
        point: LatLng(zone.latitude, zone.longitude),
        radius: MapConstants.heatmapRadius,
        useRadiusInMeter: true,
        color: zone.assessment.displayColor
            .withValues(alpha: MapConstants.heatmapOpacity * weight),
        borderColor: zone.assessment.displayColor,
        borderStrokeWidth: 1.0,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    return zones.where((z) => z.isHighRisk).map((zone) {
      final isPatrolled = patrolRecords.containsKey(zone.zoneId);
      return Marker(
        point: LatLng(zone.latitude, zone.longitude),
        width: 36,
        height: 36,
        child: Tooltip(
          message:
              '${zone.assessment.riskLevel} — ${(zone.assessment.confidence * 100).toStringAsFixed(0)}% confidence',
          child: Icon(
            Icons.location_on,
            color: isPatrolled ? Colors.green : Colors.red,
            size: 32,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter:
            LatLng(MapConstants.chennaiLat, MapConstants.chennaiLng),
        initialZoom: MapConstants.defaultZoom,
        minZoom: 9.0,
        maxZoom: 16.0,
        backgroundColor: Color(0xFF0d1117),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.rakshak.app',
        ),
        CircleLayer(circles: _buildCircles()),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/time_context.dart';
import '../../../shared/constants.dart';

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  Timer? _timer;
  TimeContext _currentTime = TimeContext.now();

  @override
  void initState() {
    super.initState();
    _startClock();
  }

  void _startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(
      TimingConstants.clockUpdateInterval,
      (_) {
        setState(() {
          _currentTime = TimeContext.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Current Time Context',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Time display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(now),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Indicators
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _currentTime.isNight == 1
                              ? Icons.nightlight_round
                              : Icons.wb_sunny,
                          size: 20,
                          color: _currentTime.isNight == 1
                              ? Colors.indigo
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentTime.isNight == 1 ? 'Night' : 'Day',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _currentTime.isWeekend == 1
                              ? Icons.weekend
                              : Icons.work_outline,
                          size: 20,
                          color: _currentTime.isWeekend == 1
                              ? Colors.green
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentTime.isWeekend == 1 ? 'Weekend' : 'Weekday',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Parameters
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildParameter('Hour', _currentTime.hour.toString()),
                _buildParameter('Day', _currentTime.dayOfWeek.toString()),
                _buildParameter('Night', _currentTime.isNight.toString()),
                _buildParameter('Weekend', _currentTime.isWeekend.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameter(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng _chennaiDefault = LatLng(13.0827, 80.2707);

  static Future<LatLng> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _chennaiDefault;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _chennaiDefault;
      }
      if (permission == LocationPermission.deniedForever) return _chennaiDefault;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return _chennaiDefault;
    }
  }

  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart' as api;
import '../models/sos_alert.dart';
import '../models/patrol.dart';

class ApiService {
  static const _timeout = Duration(seconds: 8);

  // ── SOS ──────────────────────────────────────────────────────────────────
  static Future<List<SosAlert>> fetchLiveSos() async {
    try {
      final res = await http
          .get(Uri.parse(api.sosLive))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => SosAlert.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];   // no mock fallback — empty means no live alerts
  }

  static Future<void> dispatchSos(String sosId) async {
    try {
      await http
          .post(Uri.parse('${api.sosDispatch}/$sosId'))
          .timeout(_timeout);
    } catch (_) {}
  }

  static Future<void> resolveSos(String sosId) async {
    try {
      await http
          .patch(Uri.parse('${api.sosResolve}/$sosId'))
          .timeout(_timeout);
    } catch (_) {}
  }

  /// Accept a SOS alert — PATCH /police/sos/{id}/status with status=dispatched
  static Future<bool> acceptSos(String sosId) async {
    try {
      final res = await http
          .patch(
            Uri.parse('${api.policeSosAccept}/$sosId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': 'dispatched'}),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Patrols ───────────────────────────────────────────────────────────────
  static Future<List<Patrol>> fetchPatrols() async {
    try {
      final res = await http
          .get(Uri.parse(api.patrolsList))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => Patrol.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Monitor screen — night mode citizens ─────────────────────────────────
  static Future<Map<String, dynamic>> fetchCitizensActive() async {
    try {
      final res = await http
          .get(Uri.parse('${api.citizensActive}?after_hour=22'))
          .timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {};
  }

  // ── Route screen — optimised route to SOS ────────────────────────────────
  static Future<Map<String, dynamic>> fetchRoute({
    required double fromLat, required double fromLng,
    required double toLat,   required double toLng,
    required String sosId,
  }) async {
    try {
      final uri = Uri.parse(api.policeRoute).replace(queryParameters: {
        'from_lat': '$fromLat', 'from_lng': '$fromLng',
        'to_lat':   '$toLat',   'to_lng':   '$toLng',
        'sos_id':   sosId,
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {};
  }

  // ── Map screen — live SOS from /police/sos/active ────────────────────────
  static Future<List<SosAlert>> fetchActiveSos({
    double officerLat = 13.0827,
    double officerLng = 80.2707,
  }) async {
    try {
      final uri = Uri.parse(api.sosActive).replace(queryParameters: {
        'officer_lat': '$officerLat',
        'officer_lng': '$officerLng',
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => SosAlert.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];   // no mock fallback
  }

  // ── Score Refresh ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> refreshScores(List<Map<String, dynamic>> zones) async {
    try {
      final res = await http
          .post(
            Uri.parse(api.scoreRefresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'zones': zones}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  // ── Patrol Optimizer ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchPatrolOptimizedRoutes({
    required List<Map<String, dynamic>> zones,
    required List<Map<String, dynamic>> patrols,
  }) async {
    final response = await http.post(
      Uri.parse(api.patrolOptimizer),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'zones': zones, 'patrols': patrols}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Patrol optimizer failed: ${response.statusCode}');
  }
}
import 'package:flutter/material.dart';
import '../models/sos_alert.dart';

class SosAlertCard extends StatelessWidget {
  final SosAlert alert;
  final VoidCallback? onTap;

  const SosAlertCard({super.key, required this.alert, this.onTap});

  Color _riskColor() {
    switch (alert.riskLevel.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFef4444);
      case 'MEDIUM': return const Color(0xFFf59e0b);
      default:       return const Color(0xFF22c55e);
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.zoneName,
                      style: const TextStyle(
                        color: Color(0xFFf0f6fc),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(),
                      style: const TextStyle(
                        color: Color(0xFF8b949e),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  alert.riskLevel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ZoneRow extends StatelessWidget {
  final String name;
  final int users;
  final String risk;
  final VoidCallback? onFlag;

  const ZoneRow({
    super.key,
    required this.name,
    required this.users,
    required this.risk,
    this.onFlag,
  });

  Color _riskColor() {
    switch (risk.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFFef4444);
      case 'ELEVATED': return const Color(0xFFf59e0b);
      default:         return const Color(0xFF22c55e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFf0f6fc),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$users unresolved journeys',
                  style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              risk,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFlag,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF30363d)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FLAG',
                style: TextStyle(
                  color: Color(0xFF8b949e),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
