import os
import datetime
from collections import namedtuple
import logging
import json
import boto3
import psycopg2
import psycopg2.extras
from cognito import CognitoAdmin

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

organization_columns = ["id",
                        "name",
                        "slug",
                        "encryption_key_id",
                        "terms",
                        "status",
                        "updated_at",
                        "created_at",
                        "node_id",
                        "custom_terms_of_service_version",
                        "size",
                        "storage_bucket"]

Organization = namedtuple("Organization", organization_columns)

default_organization_name = "__sandbox__"

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
    log.info(f"connect() host: {creds['host']} database: {creds['database']} user: {creds['user']} password: {creds['password']}")
    try:
        conn = psycopg2.connect("dbname='"+creds['database'] + "' user='"+creds['user'] + "' password='"+creds['password']+"'" + "host='"+creds['host'] + "'")
        log.info(f"Connected to database {creds['database']} on {creds['host']}")
    except psycopg2.errors.OperationalError as e:
        log.error(f"Database connection error: {e} - {e.diag.severity} - {e.diag.message_primary}")
        raise e
    return conn

def lookup_user(predicate):
    conn = connect()
    query = f"SELECT * FROM pennsieve.users WHERE {predicate}"
    log.info(f"lookup_user() query: {query}")
    cur = conn.cursor()
    cur.execute(query)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    log.info(f"lookup_user() found {len(rows)} user(s)")
    log.info(f"lookup_user() rows:")
    log.info(rows)
    if len(rows) > 0:
        return [User(*row) for row in rows]
    else:
        return None

def create_new_user():
    # create Cognito User
    # create Pennsieve.User
    # add Pennsieve.User to sandbox organization
    # return a User
    return None
    
def link_orcid_to_cognito(cognito_admin, orcid_id, cognito_id):
    link_result = cognito_admin.link_provider_for_user(cognito_id, "ORCID", "user_id", orcid_id) 
    update_result = cognito_admin.update_user_attributes(cognito_id, "custom:orcid", orcid_id)
    return CognitoAdmin.action_succeeded(link_result)

def link_orcid_identity(cognito_admin, provider_id):
    # function to select the correct Pennsieve user returned from the database query
    def select_user(user_list):
        # for now, return the first one on the list
        return user_list[0]
    
    # uppercase the orcid_id (seems AWS event lowercases alpha characters)
    orcid_id = provider_id.upper()
    log.info(f"link_orcid_identity() orcid_id: {orcid_id}")
    
    query_predicate = "orcid_authorization @> " + "'{" + "\"orcid\" : " + "\"" + orcid_id + "\"" + "}'"
    user_list = lookup_user(query_predicate)
    if user_list is not None:
        user = select_user(user_list)
        return link_orcid_to_cognito(cognito_admin, orcid_id, user.cognito_id)
    else:
        #log.info(f"link_orcid() no Pennsieve user was found with orcid_id: {orcid_id}")
        #raise ValueError(f"There is no Pennsieve user linked to ORCID Id {orcid_id}")
        #return False
        user = create_new_user()
        if user is not None:
            return link_orcid_to_cognito(cognito_admin, orcid_id, user.cognito_id)
        else:
            log.error("something failed in new user creation and linking to external identity")
            return False

def link_external_identity(event):
    user_pool_id = event['userPoolId']
    cognito_admin = CognitoAdmin(user_pool_id)
    
    provider_name = event['userName'].split("_")[0].upper()
    provider_id = event['userName'][len(provider_name)+1:]
    if provider_name == "ORCID":
        return link_orcid_identity(cognito_admin, provider_id)
    else:
        log.info(f"link_external() provider {provider_name} is not supported at this time")
        return False

def process_event(event):
    trigger_source = event['triggerSource']
    if trigger_source == "PreSignUp_ExternalProvider":
        event["response"]["autoConfirmUser"] = event["response"]["autoVerifyPhone"] = event["response"]["autoVerifyEmail"] = link_external_identity(event)
    else:
        log.info(f"process_event() trigger_source {trigger_source} will not be processed (not applicable in this context)")
    return event

def handler(event, context):
    log.info(f"handler() new event")
    log.info(event)
    return process_event(event)
