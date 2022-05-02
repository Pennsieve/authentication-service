import os
import datetime
from collections import namedtuple
import logging
import json
import random
import string
import uuid
import boto3
import psycopg2
import psycopg2.extras
from cognito import CognitoAdmin
from database import ConnectionParameters, Database

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
                "cognito_id",
                "is_integration_user"]

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

organization_user_columns = ["organization_id", 
                             "user_id", 
                             "permission_bit", "created_at", "updated_at"]

OrganizationUser = namedtuple("OrganizationUser", organization_user_columns)

default_organization_slug = "__sandbox__"
default_permission_bit = 4

bogus_email_domain = "pennsieve-nonexistent.email"

log = logging.getLogger()
log.setLevel(logging.INFO)

database = Database()

def get_credentials():
    pennsieve_env = os.environ['PENNSIEVE_ENV']
    ssm = boto3.client('ssm')
    return ConnectionParameters(host = ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-host', WithDecryption=True)['Parameter']['Value'],
                                database = ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-db', WithDecryption=True)['Parameter']['Value'],
                                username = ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-user', WithDecryption=True)['Parameter']['Value'],
                                password = ssm.get_parameter(Name=f'/{pennsieve_env}/authentication-service/postgres-password', WithDecryption=True)['Parameter']['Value'])

def column_list(columns):
    return ",".join(columns)

def type_columns(T):
    return column_list(T._fields)

def value_list(values):
    string = ""
    sep = ""
    for item in values:
        if type(item) == str:
            string = f"{string}{sep}'{item}'"
        if type(item) == int:
            string = f"{string}{sep}{item}"
        if type(item) == type(None):
            string = f"{string}{sep}null"
        sep = ","
    return string

def lookup_pennsieve_user(predicate):
    query = f"SELECT {type_columns(User)} FROM pennsieve.users WHERE {predicate}"
    log.info(f"lookup_pennsieve_user() query: {query}")
    rows = database.select(query)
    log.info(f"lookup_pennsieve_user() found {len(rows)} row(s)")
    log.info(rows)
    if len(rows) > 0:
        return [User(*row) for row in rows]
    else:
        return None

def lookup_pennsieve_organization(slug):
    query = f"SELECT {type_columns(Organization)} FROM pennsieve.organizations WHERE slug='{slug}'"
    log.info(f"lookup_pennsieve_organization() query: {query}")
    rows = database.select(query)
    log.info(f"lookup_pennsieve_organization() found {len(rows)} row(s)")
    log.info(rows)
    if len(rows) > 0:
        return Organization(*rows[0])
    else:
        return None

def add_pennsieve_user_to_organization(user, organization, permission_bit=default_permission_bit):
    statement = f"INSERT INTO pennsieve.organization_user(organization_id, user_id, permission_bit) VALUES({organization.id}, {user.id}, {permission_bit}) RETURNING {type_columns(OrganizationUser)}"
    log.info(f"add_pennsieve_user_to_organization() statement: {statement}")
    rows = database.insert(statement)
    log.info(f"add_pennsieve_user_to_organization() insert returned {len(rows)} row(s)")
    log.info(rows)
    if len(rows) > 0:
        return OrganizationUser(*rows[0])
    else:
        return None

def create_pennsieve_user(email, cognito_id, preferred_org_id):
    node_id = f"N:user:{uuid.uuid4()}"
    color = "#F45D01"

    user_insert_columns = [ "email",
                            "first_name",
                            "last_name",
                            "credential",
                            "color",
                            "url",
                            "authy_id",
                            "is_super_admin",
                            "preferred_org_id",
                            "status",
                            "node_id",
                            "middle_initial",
                            "degree",
                            "cognito_id",
                            "is_integration_user" ]
    user_insert_values = [  email,
                            "orcid",
                            "login",
                            "",
                            color,
                            "",
                            0,
                            "f",
                            preferred_org_id,
                            "t",
                            node_id,
                            "",
                            None,
                            cognito_id,
                            "f" ]
    
    statement = f"INSERT INTO pennsieve.users({column_list(user_insert_columns)}) VALUES({value_list(user_insert_values)}) RETURNING *"
    log.info(f"create_pennsieve_user() statement: {statement}")
    
    rows = database.insert(statement)
    log.info(f"create_pennsieve_user() insert returned {len(rows)} row(s)")
    log.info(rows)
    if len(rows) > 0:
        return User(*rows[0])
    else:
        return None

def random_password():
    def random_number():
        return random.SystemRandom().choice(string.digits)
    
    def random_lowercase():
        return random.SystemRandom().choice(string.ascii_lowercase)
    
    def random_uppercase():
        return random.SystemRandom().choice(string.ascii_uppercase)
    
    def random_punctuation():
        return random.SystemRandom().choice(".,+-/=:!%^")
    
    def random_prefix():
        return f"{random_number()}{random_lowercase()}{random_punctuation()}{random_uppercase()}"
    
    def random_string(N):
        C = string.ascii_uppercase + string.ascii_lowercase + string.digits
        return ''.join(random.SystemRandom().choice(C) for _ in range(N))
    
    def random_uuid():
        return str(uuid.uuid4())
    
    return f"{random_uuid()}{random_uppercase()}"

def create_cognito_user(cognito_admin, email):
    # create Cognito User
    password = random_password()
    response = cognito_admin.create_user(email, temp_password = password)
    log.info(f"cognito_admin.create_user() response: {response}")
    if not CognitoAdmin.action_succeeded(response):
        return None
    cognito_id = response['User']['Username']
    
    # set user's password, so they are not in FORCE_CHANGE_PASSWORD and can request a password reset
    response = cognito_admin.set_user_password(cognito_id, password, permanent=True)
    log.info(f"cognito_admin.set_user_password() response: {response}")
    if not CognitoAdmin.action_succeeded(response):
        log.warning(f"cognito_admin.set_user_password() was not successful")
    
    # return the Cognito Id of the newly created user
    return cognito_id
    
def create_new_user(cognito_admin, email):
    cognito_id = create_cognito_user(cognito_admin, email)
    if cognito_id is None:
        return None
    
    # lookup default organization
    organization = lookup_pennsieve_organization(default_organization_slug)
    if organization is None:
        log.error(f"create_new_user() failed to lookup organization: {default_organization_slug}")
        return None
    
    # create Pennsieve.User
    user = create_pennsieve_user(email, cognito_id, organization.id)

    # add Pennsieve.User to organization
    if user is None:
        log.error(f"create_new_user() failed to create Pennsieve.User")
        return None
        
    # add user to organization
    org_user = add_pennsieve_user_to_organization(user, organization)

    # return the Pennsieve.User
    log.info(f"create_new_user() created user with id: {user.id} cognito_id: {user.cognito_id} email: {user.email}")
    return user
    
def link_orcid_to_cognito(cognito_admin, orcid_id, cognito_id):
    log.info(f"link_orcid_to_cognito() orcid_id: {orcid_id} -> cognito_id: {cognito_id}")
    link_result = cognito_admin.link_provider_for_user(cognito_id, "ORCID", "user_id", orcid_id) 
    update_result = cognito_admin.update_user_attributes(cognito_id, "custom:orcid", orcid_id)
    return CognitoAdmin.action_succeeded(link_result)

def link_orcid_identity(cognito_admin, provider_id):
    # function to select the correct Pennsieve user returned from the database query
    def select_user(user_list):
        # for now, return the first one on the list
        return user_list[0]
    
    def synthesize_email(orcid_id):
        return f"orcid+{orcid_id}@{bogus_email_domain}"
    
    # uppercase the orcid_id (seems AWS event lowercases alpha characters)
    orcid_id = provider_id.upper()
    log.info(f"link_orcid_identity() orcid_id: {orcid_id}")
    
    # Use ORCID iD to lookup user in Pennsieve database. If no user has linked this ORCID iD to
    # their Pennsieve account, then create a new user (thus permitting sign-up with ORCID iD).
    query_predicate = "orcid_authorization @> " + "'{" + "\"orcid\" : " + "\"" + orcid_id + "\"" + "}'"
    user_list = lookup_pennsieve_user(query_predicate)
    if user_list is not None:
        user = select_user(user_list)
    else:
        user = create_new_user(cognito_admin, synthesize_email(orcid_id))
    
    # Link the Cognito user to the ORCID identity. This will return the Cognito identity as the logged
    # in user, authenticated with ORCID iD credentials.
    if user is not None:
        return link_orcid_to_cognito(cognito_admin, orcid_id, user.cognito_id)
    else:
        # TODO: might want to raise an exception here
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
        database.connect(get_credentials())
        event["response"]["autoConfirmUser"] = event["response"]["autoVerifyPhone"] = event["response"]["autoVerifyEmail"] = link_external_identity(event)
        database.disconnect()
    else:
        log.info(f"process_event() trigger_source {trigger_source} will not be processed (not applicable in this context)")
    return event

def handler(event, context):
    log.info(f"handler() new event")
    log.info(event)
    return process_event(event)
