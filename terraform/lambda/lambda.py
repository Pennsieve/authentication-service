import urllib
from string import Template

def lambda_handler(event, _context):
    with open("./new-account-creation.template.html") as file:
        file_contents = file.read()

    code = urllib.parse.quote(event["request"]["codeParameter"], safe = "")
    username = event["request"]["usernameParameter"]

    template = Template(file_contents)
    email_message = template.substitute({
        'code': code,
        'username': username
    })

    sms_message_template = Template(
        "Please visit https://app.pennsieve.net/invitation/accept/${username}/${code}"
    )
    sms_message = sms_message_template.substitute({
        'code': code,
        'email': username
    })

    response = {
        "smsMessage": sms_message,
        "emailSubject": "Welcome to Pennsieve - setup your account",
        "emailMessage": email_message
    }

    return response
