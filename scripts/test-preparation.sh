#!/bin/bash

#### Check if the thing name and device token are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <thing-name> <device-token>"
  exit 1
fi

THING_NAME=$1
DEVICE_TOKEN=$2

PEM_FILE="lumenisIOT.pem"
INSTANCE_USER="ec2-user"
INSTANCE_HOST="redacted"

tar -czvf setup-iot-thing.tar.gz script.py test.iot.sh requirements.txt
scp -i "$PEM_FILE" setup-iot-thing.tar.gz  "$INSTANCE_USER@$INSTANCE_HOST":/home/ec2-user

ssh -i "$PEM_FILE" "$INSTANCE_USER@$INSTANCE_HOST" << EOF
sudo -i
mv /home/ec2-user/setup-iot-thing.tar.gz /root
cd /root
ls -lh
tar -xzvf setup-iot-thing.tar.gz
chmod +x test.iot.sh
./test.iot.sh $THING_NAME $DEVICE_TOKEN
EOF