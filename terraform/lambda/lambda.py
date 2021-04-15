import urllib
import os
from string import Template


def lambda_handler(event, _context):
    if event["triggerSource"] == "CustomMessage_AdminCreateUser":
        return handle_admin_create_user(event)
    else:
        return event


def handle_admin_create_user(event):
    with open("./new-account-creation.template.html") as file:
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
        "Please visit https://app.${domain}/invitation/accept/${username}/${code}"
    )
    sms_message = sms_message_template.substitute({
        'code': code,
        'username': username,
        'domain': os.environ.get("PENNSIEVE_DOMAIN")
    })

    event["response"]["smsMessage"] = sms_message
    event["response"]["emailSubject"] = "Welcome to Pennsieve - setup your account"
    event["response"]["emailMessage"] = email_message

    return event
