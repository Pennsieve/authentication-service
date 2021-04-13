import os
from string import Template

def lambda_handler(event, context):
    with open("./new-account-creation.template.html") as file:
        fileContents = file.read()

    code = event["request"]["codeParameter"]
    username = event["request"]["usernameParameter"]

    template = Template(fileContents)
    emailMessage = template.substitute({
        'code': code,
        'username': username
    })

    smsMessageTemplate = Template("Please visit https://app.pennsieve.net/invitation/accept/${username}/${code}"
    smsMessage = smsMessageTemplate.substitute({
        'code': code,
        'email': username
    })

    response = {
        smsMessage = smsMessage
        emailSubject = "Welcome to Pennsieve - setup your account"
        emailMessage = emailMessage
    }

    return response
