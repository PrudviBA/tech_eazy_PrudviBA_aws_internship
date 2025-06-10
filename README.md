# AWS EC2 Deployment - Internship Assignment

This project automates the deployment of a Java-based application on an AWS EC2 instance. It meets all the instructions outlined in the assignment.

---

## Instructions
### 1. **Sign up to  AWS free tier** if not already done.
### 2. **Configure AWS CLI in your local environment**  
   - Make sure the AWS CLI is installed and configured with your AWS credentials:  
     ```bash
     aws configure
     ```
   - Provide your AWS Access Key ID, Secret Access Key, default region, and output format.  
   - This is required for the deployment script to manage EC2 resources.
### 3. Run the deployment script (deploy.sh) which will automatically:
   - Launch an EC2 instance of the specified type
   - Install Java 21, Git, Maven, and other dependencies
   - Clone the application repository from https://github.com/techeazy-consulting/techeazy-devops
   - Build and deploy the Java application
   - Test if the app is reachable on port 80
   - Stop the instance after deployment to save costs
### 4 . Configure the deployment stage by passing a parameter (Dev or Prod) to the script.
   - This selects the appropriate config file (dev_config or prod_config) automatically.
   - The config file includes values for instance type, AMI ID, security group, and other instance-specific details.
   - Dependencies (like Java, Git, Maven) and repo URL are handled within the script itself.
### 5. Run the deployment script to start the automated EC2 deployment:
 ```
./deploy.sh Dev
```
  - Replace Dev with Prod to deploy to the production environment.
  - The script:
  - Spins up the EC2 instance.
  - Installs Java 21, Git, and Maven.
  - Clones the application from the provided GitHub repository.
  - Builds the Java application using Maven.
  - Runs the application and checks if it’s accessible on port 80.
  - Stops the instance after deployment to save costs.
### 6. API Testing using Postman:
  - An empty Postman collection JSON file is included in the resources/ directory as a placeholder.
  - This can be updated later if you need to test actual API endpoints, but currently, it’s empty.
### 7. Clean Up:
  - After testing the deployment, terminate the EC2 instance manually or via the script to avoid extra AWS costs.
  - The deployment script automatically stops the instance at the end, but you can verify in the AWS console to ensure it’s stopped.
### 8. Debug Note
  - This branch is for debugging the port 80 accessibility issue.

    




