import os
import json
from pypureclient import flasharray
import logging
import boto3

#Retrieve environment variables 
cbs_ip = os.environ['CBS_IP']
cbs_username = os.environ['CBS_USERNAME']
cbs_client_id = os.environ['CLIENT_ID']
cbs_key_id = os.environ['KEY_ID']
cbs_issuer = os.environ['CLIENT_API_ISSUER']

#Change Directory to /tmp 
os.chdir('/tmp')

#Retrive the private key from SSM parameter store
ssm = boto3.client('ssm')
parameter = ssm.get_parameter(Name='/cbs/apiclient/privatekey', WithDecryption=False)

#Write the private key to a file 
with open('private.pem', 'w') as f:
     f.write(parameter['Parameter']['Value'])

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
   
    #Create client and authintacte
    client = flasharray.Client(cbs_ip,
                            private_key_file='/tmp/private.pem',
                            username=cbs_username,
                            client_id=cbs_client_id,
                            key_id=cbs_key_id,
                            issuer=cbs_issuer)
    
    try:
        array = client.get_arrays()
        print(list(array.items))
    except Exception as e:
        logger.error("Error occurred while fetching the array info: {}".format(e))
        status = 'Failed to get the the data. Error: {}'.format(e)
    else:
        status = 'Seccussful'
        
    return status