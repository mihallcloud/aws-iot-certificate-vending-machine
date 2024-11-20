import os
import sys
import boto3
from urllib import request, parse
import json
from botocore.exceptions import ClientError
# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table_name = "deviceInfo"  # Replace with your actual DynamoDB table name
table = dynamodb.Table(table_name)
def insert_into_dynamodb(serial_number, device_token):
    """Insert serialNumber and deviceToken into DynamoDB."""
    try:
        # Insert item into DynamoDB table
        response = table.put_item(
            Item={
                'serialNumber': serial_number,
                'deviceToken': device_token
            }
        )
        print(f"Inserted {serial_number} into DynamoDB")
    except ClientError as e:
        print(f"Error inserting into DynamoDB: {e.response['Error']['Message']}")
# Function to generate and save certificates
def generate_and_save_certificates(serial_number, device_token):
    # API URL and query parameters
    url = "https://redacted.execute-api.us-east-1.amazonaws.com/Prod/getcert"
    params = {
        "serialNumber": serial_number,
        "deviceToken": device_token
    }
    # Encode the parameters
    query_string = parse.urlencode(params)
    full_url = f"{url}?{query_string}"
    
    # Send the request to get the certificate data
    with request.urlopen(full_url) as response:
        cert_data = json.loads(response.read().decode())
    
    # Inspect the received data
    print("Certificate Response: ", cert_data)
    # Check if the expected data fields exist in the response
    if "certificatePem" in cert_data and "keyPair" in cert_data and "RootCA" in cert_data:
        # Extract necessary certificate components
        certificate_pem = cert_data["certificatePem"]
        public_key = cert_data["keyPair"]["PublicKey"]
        private_key = cert_data["keyPair"]["PrivateKey"]
        root_ca = cert_data["RootCA"]
        # Paths to store certificates
        cert_dir = "redacted"
        cert_pem_file = os.path.join(cert_dir, "deviceCert.pem")
        private_key_file = os.path.join(cert_dir, "privateKey.pem")
        public_key_file = os.path.join(cert_dir, "publicKey.pem")
        root_ca_file = os.path.join(cert_dir, "rootCA.pem")
        # Create directory if it doesn't exist
        os.makedirs(cert_dir, exist_ok=True)
        # Write the certificate files
        with open(cert_pem_file, "w") as cert_file:
            cert_file.write(certificate_pem)
            print(f"Certificate saved to {cert_pem_file}")
        with open(private_key_file, "w") as private_file:
            private_file.write(private_key)
            print(f"Private key saved to {private_key_file}")
        with open(public_key_file, "w") as public_file:
            public_file.write(public_key)
            print(f"Public key saved to {public_key_file}")
        with open(root_ca_file, "w") as root_ca_cert:
            root_ca_cert.write(root_ca)
            print(f"Root CA certificate saved to {root_ca_file}")
    else:
        print("Error: Missing required certificate data in the response.")
# Main function to take input parameters and execute the process
def main():
        # Check if the correct number of arguments are provided
    if len(sys.argv) != 3:
        print("Usage: script.py <serialNumber> <deviceToken>")
        sys.exit(1)
    
    # Take input for serialNumber and deviceToken from command-line arguments
    serial_number = sys.argv[1]
    device_token = sys.argv[2]
    # Insert the device info into DynamoDB
    insert_into_dynamodb(serial_number, device_token)
    # Generate and save the certificates
    generate_and_save_certificates(serial_number, device_token)
if __name__ == "__main__":
    main()