#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0f63039a616382c25" # replace with your SG ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "frontend")
ZONE_ID="Z0443285370E15R10QIN" # replace with your ZONE ID
DOMAIN_NAME="dsops84.space" # replace with your domain

#for instance in $@ 
for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
    PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    # Get Private IP
    if [ $instance != "frontend" ]; then
        IP=$PRIVATE_IP
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$PUBLIC_IP
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance: Private IP = $PRIVATE_IP | Public IP = $PUBLIC_IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }
    '
done