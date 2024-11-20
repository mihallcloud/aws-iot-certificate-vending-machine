#!/bin/bash

#### Check if the thing name and device token are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <thing-name> <device-token>"
  exit 1
fi

THING_NAME=$1
DEVICE_TOKEN=$2

##### For Amazon Linux 2023(install preqrequisites + greengrass installer):
sudo dnf install java-11-amazon-corretto -y
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-nucleus-latest.zip > greengrass-nucleus-latest.zip
unzip greengrass-nucleus-latest.zip -d /root/GreengrassInstaller && rm greengrass-nucleus-latest.zip


##### Install Python dependencies
sudo dnf install python3-pip -y
pip install -r requirements.txt
##### download certs
python3 script.py $THING_NAME $DEVICE_TOKEN

##### Create the Greengrass configuration file
config_file="/root/GreengrassInstaller/config.yaml"
# IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --query 'endpointAddress' --output text)
# IOT_CRED_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:CredentialProvider --query 'endpointAddress' --output text)
IOT_ENDPOINT="redacted.iot.us-east-1.amazonaws.com"
IOT_CRED_ENDPOINT="redacted.credentials.iot.us-east-1.amazonaws.com"
# Write the YAML content to the file
cat <<EOL > $config_file
---
system:
  certificateFilePath: "/greengrass/v2/certs/deviceCert.pem"
  privateKeyPath: "/greengrass/v2/certs/privateKey.pem"
  rootCaPath: "/greengrass/v2/certs/rootCA.pem"
  rootpath: "/greengrass/v2"
  thingName: "$THING_NAME"
services:
  aws.greengrass.Nucleus:
    componentType: "NUCLEUS"
    version: "2.13.0"
    configuration:
      awsRegion: "us-east-1"
      iotRoleAlias: "GreengrassCoreTokenExchangeRoleAlias"
      iotDataEndpoint: "$IOT_ENDPOINT"
      iotCredEndpoint: "$IOT_CRED_ENDPOINT"
EOL

echo "Configuration file created at $config_file"

sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE \
  -jar /root/GreengrassInstaller/lib/Greengrass.jar \
  --init-config /root/GreengrassInstaller/config.yaml \
  --component-default-user ggc_user:ggc_group \
  --setup-system-service true