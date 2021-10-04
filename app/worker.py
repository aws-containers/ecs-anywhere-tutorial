import boto3
import os
import json
import time

#Import env variables
print("Importing the env variables\r")
queue_url = os.getenv('SQS_QUEUE_URL')
source_folder = os.getenv('EFS_SOURCE_FOLDER')              
destination_folder = os.getenv('EFS_DESTINATION_FOLDER')    
aws_region = os.getenv('AWS_REGION')
print("Env variables have been imported as follows:\r")
print("SQS_QUEUE_URL: " + queue_url + "\r")
print("EFS_SOURCE_FOLDER: " + source_folder + "\r")
print("EFS_DESTINATION_FOLDER: " + destination_folder + "\r")
print("AWS_REGION: " + aws_region + "\r")

# Create directories if they do not exist (only used when mounting a single folder)
# e.g. if you only mount /data, these create /data/$EFS_SOURCE_FOLDER and /data/$EFS_DESTINATION_FOLDER
# alternative you can mount source and destination separarely 
if not os.path.exists(source_folder):
    os.makedirs(source_folder)
if not os.path.exists(destination_folder):
    os.makedirs(destination_folder)

# Create SQS client
print("Initializing the boto client\r")
sqs = boto3.client('sqs', region_name=aws_region)
print("Boto client has been initialized\r")

# Receive message from SQS queue
print("Entering the infinite queue monitoring loop\r")
while True:
    response = sqs.receive_message(
                    QueueUrl=queue_url,
                    AttributeNames=['SentTimestamp'],
                    MaxNumberOfMessages=1,
                    MessageAttributeNames=['All'],
                    VisibilityTimeout=0,
                    WaitTimeSeconds=20
                    )

    # Check if a message was received 
    if 'Messages' in response: 
        print("Found a new message...\r")
        message = response['Messages'][0]
        receipt_handle = message['ReceiptHandle']
        message_element=json.dumps(message)
        message_json=json.loads(message_element)
        
        file_name=message_json['Body']
        
        # Business logic: rename file and move folder     
        print("Processing file " + source_folder+file_name + " and moving to " + destination_folder+file_name+"_has_been_processed\r")
        try:
            os.rename(source_folder+file_name, destination_folder+file_name+"_has_been_processed")
        except OSError as err:
            print("OS error: {0}".format(err))
            
        time.sleep(10) # This adds some delay to make the demo flow slightly more realistic and easy to watch 
    
        #Delete received message from queue
        sqs.delete_message(
                    QueueUrl=queue_url,
                        ReceiptHandle=receipt_handle
                        )
        print('Deleted message : %s\r' % message)


