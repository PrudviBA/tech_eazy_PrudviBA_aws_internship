#!/bin/bash

# Usage: ./deploy.sh <Stage>
# Example: ./deploy.sh dev

if [ -z "$1" ]; then
  echo "Error: Please provide the stage (dev/prod)."
  exit 1
fi

STAGE=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Load the correct config file
if [ "$STAGE" == "dev" ]; then
  source dev_config
elif [ "$STAGE" == "prod" ]; then
  source prod_config
else
  echo "Error: Invalid stage. Use 'dev' or 'prod'."
  exit 1
fi

# Get your current public IP with /32 mask
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

echo "Authorizing SSH access on port 22 from $MY_IP to security group $SECURITY_GROUP..."

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP \
  --protocol tcp \
  --port 22 \
  --cidr $MY_IP 2>/dev/null || echo "SSH ingress rule for $MY_IP already exists or failed to add."

# Ensure port 80 HTTP access open for all
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 2>/dev/null || echo "HTTP ingress rule already exists or failed to add."

# Create EC2 instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count $INSTANCE_COUNT \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait until instance is running
echo "Waiting for instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
echo "Instance is running."

# Get Public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Public IP: $PUBLIC_IP"

# Wait for SSH to be ready dynamically
echo "Waiting for SSH service to be available..."
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$KEY_NAME.pem" ubuntu@$PUBLIC_IP exit 2>/dev/null; do
  echo "SSH not ready yet. Sleeping for 10 seconds..."
  sleep 10
done

echo "SSH is ready!"

# Deploy the app via SSH
echo "Connecting to EC2 and deploying app..."
ssh -o StrictHostKeyChecking=no -i "$KEY_NAME.pem" ubuntu@$PUBLIC_IP << EOF
  sudo apt-get update
  sudo apt-get install -y openjdk-21-jdk git maven
  git clone https://github.com/techeazy-consulting/techeazy-devops.git
  cd techeazy-devops
  chmod +x mvnw
  ./mvnw clean package
  sudo nohup java -jar target/*.jar > app.log 2>&1 &
EOF

echo "App deployed and running on $PUBLIC_IP:80"

# Wait a bit for the app to start
echo "Waiting for app to become accessible..."

# Test if app is reachable on port 80
echo "Testing if app is reachable on port 80..."
if curl -s --head --request GET http://$PUBLIC_IP | grep "200 OK" > /dev/null; then
  echo "App is up and running!"
else
  echo "App is not reachable. Please check manually."
fi

# Stop the instance to save cost
echo "Stopping EC2 instance to save cost..."
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
echo "Instance stopped."

echo "Deployment script completed."
