import boto3

class CognitoAdmin:
    def __init__(self, user_pool_id):
        self.__user_pool_id = user_pool_id
        self.__client = boto3.client('cognito-idp')
        
    def action_succeeded(response):
        return 'ResponseMetadata' in response \
            and 'HTTPStatusCode' in response['ResponseMetadata'] \
            and response['ResponseMetadata']['HTTPStatusCode'] == 200

    def create_user(self, email, invite_path="self-service", temp_password="New+Password-1"):
        response = self.__client.admin_create_user(
            UserPoolId=self.__user_pool_id,
            Username=email,
            UserAttributes=[
                {
                    'Name': 'email',
                    'Value': email
                },
                {
                    'Name': 'email_verified',
                    'Value': 'true'
                },
                {
                    'Name': 'custom:invite_path',
                    'Value': invite_path
                },
            ],
            TemporaryPassword=temp_password,
            ForceAliasCreation=False,
            DesiredDeliveryMediums = ['EMAIL'],
            MessageAction='SUPPRESS'
        )
        # TODO: return the Cognito Id
        return response
    
    def confirm_user(self, username):
        response = self.__client.admin_confirm_sign_up(
            UserPoolId=self.__user_pool_id,
            Username=username
        )
        return response

    def link_provider_for_user(self, destination_user_name, source_provider_name, source_attribute_name, source_attribute_value):
        response = self.__client.admin_link_provider_for_user(
            UserPoolId=self.__user_pool_id,
            DestinationUser={
                'ProviderName': 'Cognito',
                'ProviderAttributeName': 'username',
                'ProviderAttributeValue': destination_user_name
            },
            SourceUser={
                'ProviderName': source_provider_name,
                'ProviderAttributeName': 'Cognito_Subject',
                'ProviderAttributeValue': source_attribute_value
            }
        )
        return response

    def set_user_password(self, username, password):
        response = self.__client.admin_set_user_password(
            UserPoolId=self.__user_pool_id,
            Username=username,
            Password=password,
            Permanent=True
        )
        return response
    
    def update_user_attributes(self, username, attribute_name, attribute_value):
        response = self.__client.admin_update_user_attributes(
            UserPoolId=self.__user_pool_id,
            Username=username,
            UserAttributes=[
                {
                    'Name': attribute_name,
                    'Value': attribute_value
                }
            ]
        )
        return response
