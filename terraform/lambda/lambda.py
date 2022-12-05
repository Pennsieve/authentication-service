import os
from string import Template
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, _context):
    logger.info('## AUTHENTICATION LAMBDA EVENT')
    logger.info(event)

    if event["triggerSource"] == "CustomMessage_AdminCreateUser":
        return handle_admin_create_user(event)
    elif event["triggerSource"] == "CustomMessage_ForgotPassword":
        return handle_forgot_password(event)
    else:
        return event


def handle_forgot_password(event):
    with open("./password-reset.template.html") as file:
        file_contents = file.read()

    code = event["request"]["codeParameter"]
    username = event["userName"]

    template = Template(file_contents)
    email_message = template.substitute({
        'code': code,
        'username': username,
        'domain': os.environ.get("PENNSIEVE_DOMAIN")
    })

    sms_message_template = Template(
        "Please visit https://app.${domain}/password?verificationCode=${code}"
    )
    sms_message = sms_message_template.substitute({
        'code': code,
        'username': username,
        'domain': os.environ.get("PENNSIEVE_DOMAIN")
    })

    event["response"]["smsMessage"] = sms_message
    event["response"]["emailSubject"] = "Pennsieve - Password Reset"
    event["response"]["emailMessage"] = email_message

    return event

def handle_admin_create_user(event):
    with open("./new-account-creation.template.html") as file:
        file_contents = file.read()

    code = event["request"]["codeParameter"]
    username = event["userName"]

    setup_url = "https://app.{}/invitation/accept".format(os.environ.get("PENNSIEVE_DOMAIN"))
    if event["request"]["userAttributes"]["custom:invite_path"] == "self-service":
        setup_url = "https://app.{}/invitation/verify".format(os.environ.get("PENNSIEVE_DOMAIN"))

    if "clientMetadata" in event["request"] and "customMessage" in event["request"]["clientMetadata"]:
        customMessage = event["request"]["clientMetadata"]
    else:
        customMessage = ""

    template = Template(file_contents)
    email_message = template.substitute({
        'code': code,
        'username': username,
        'setup_url': setup_url,
        'domain': os.environ.get("PENNSIEVE_DOMAIN"),
        'customMessage': customMessage
    })

    sms_message_template = Template(
        "Please visit ${setup_url}/${username}/${code}"
    )
    sms_message = sms_message_template.substitute({
        'code': code,
        'username': username,
        'setup_url': setup_url
    })

    event["response"]["smsMessage"] = sms_message
    event["response"]["emailSubject"] = "Welcome to Pennsieve - setup your account"
    event["response"]["emailMessage"] = email_message

    return event
