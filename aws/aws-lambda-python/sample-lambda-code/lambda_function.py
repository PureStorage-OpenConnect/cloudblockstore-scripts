import os
import json
from pypureclient import flasharray
import logging
import boto3

cbs_ip = os.environ['CBS_IP']

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
                            username='pureuser',
                            client_id='cea503f0-b809-4682-8dd9-0a7367f1a1fa',
                            key_id='80bd8068-30fb-4d70-a598-50b6062c3db9',
                            issuer='lambda')
    
    try:
        array = client.get_arrays()
        print(list(array.items))
    except Exception as e:
        logger.error("Error occurred while fetching the array info: {}".format(e))
        status = 'Failed to get the the data. Error: {}'.format(e)
    else:
        status = 'Seccussful'
        
    return status