import os
import datetime
from collections import namedtuple
import logging
import psycopg2
import psycopg2.extras
import boto3

user_columns = ["id",
                "email",
                "first_name",
                "last_name",
                "credential",
                "color",
                "url",
                "authy_id",
                "is_super_admin",
                "preferred_org_id",
                "status",
                "updated_at",
                "created_at",
                "node_id",
                "orcid_authorization",
                "middle_initial",
                "degree",
                "cognito_id"]

User = namedtuple("User", user_columns)

log = logging.getLogger()
log.setLevel(logging.INFO)

def get_credentials():
    pennsieve_env = os.environ['PENNSIEVE_ENV']
    ssm = boto3.client('ssm')
    return {"host": ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-host', WithDecryption=True)['Parameter']['Value'], 
            "database": ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-db', WithDecryption=True)['Parameter']['Value'], 
            "user": ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-user', WithDecryption=True)['Parameter']['Value'],
            "password": ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-password', WithDecryption=True)['Parameter']['Value']}

def connect():
    creds = get_credentials()
    log.debug(f"connect() host: {creds['host']} database: {creds['database']} user: {creds['user']} password: {creds['password']}")
    try:
        conn = psycopg2.connect("dbname='"+creds['database'] + "' user='"+creds['user'] + "' password='"+creds['password']+"'" + "host='"+creds['host'] + "'")
        log.info(f"Connected to database {creds['database']} on {creds['host']}")
    except psycopg2.errors.OperationalError as e:
        log.error(f"Database connection error: {e} - {e.diag.severity} - {e.diag.message_primary}")
        raise e
    return conn

def update_user(conn, email, cognito_id):
    statement = f"UPDATE pennsieve.users SET cognito_id='{cognito_id}' WHERE email='{email}'"
    log.info(f"update_user() statement: {statement}")
    cur = conn.cursor()
    cur.execute(statement)
    count = cur.rowcount
    log.info(f"update_user() updated {count} row(s)")
    conn.commit()
    cur.close()
    return count

def lookup_user(conn, email):
    query = f"SELECT * FROM pennsieve.users WHERE email='{email}'"
    log.info(f"lookup_user() query: {query}")
    cur = conn.cursor()
    cur.execute(query)
    rows = cur.fetchall()
    cur.close()
    log.info(f"lookup_user() number of rows {len(rows)}")
    log.info(f"lookup_user() rows:")
    log.info(rows)
    if len(rows) == 1:
        return User(*rows[0])
    else:
        return None

def process_event(event):
    try:
        cognito_id = event['userName']
        email = event['request']['userAttributes']['email']
    except KeyError:
        log.error(f"process_event() userName (cognito_id) or email address not found in event")
        return

    conn = connect()
    user = lookup_user(conn, email)
    if user is not None:
        log.info(f"process_event() user found: {user.email}")
        if cognito_id != user.cognito_id:
            update_user(conn, email, cognito_id)
        else:
            log.info(f"process_event() user is up-to-date: {user.email} / {user.cognito_id}")
    else:
        log.warn(f"process_event() user not found: {email}")
    
    conn.close()
    return

def handler(event, context):
    log.info(f"handler() event:")
    log.info(event)
    process_event(event)
    return event
