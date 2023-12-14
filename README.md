# Reddit-clone-aws-deployment

This repository contains Terraform configurations and Kubernetes manifest files for deploying a Reddit clone application on AWS architecture.

![Architecture Snapshot](https://s3.ap-northeast-1.amazonaws.com/motulaal.io/reddit+project/architecture+snapshot.png)

## Overview

This project utilizes Terraform to provision the following resources on AWS:

- **VPC and Subnet**: Creates a Virtual Private Cloud (VPC) along with a public subnet for deploying the Reddit Clone application.
- **Internet Gateway and Route Table**: Establishes an Internet Gateway and Route Table for internet connectivity to the resources within the VPC.
- **Security Groups**: Defines security groups with specific inbound and outbound rules for instances.
- **EC2 Instances**: Deploys EC2 instances for Continuous Integration (CI) and Continuous Deployment (CD) purposes.

## Prerequisites

Before using this Terraform configuration, make sure you have:

- AWS CLI configured with necessary permissions.
- Terraform installed on your local machine.

## Configuration

### Variables

Adjust the variables in `variables.tf` to suit your requirements:

- `region`: AWS region where resources will be deployed.
- `vpc_cidr_block`: CIDR block for the VPC.
- `subnet_cidr_block`: CIDR block for the subnet.
- `ami_id`: ID of the Amazon Machine Image (AMI) to be used for instances.
- Other variables for instance types, CIDR blocks, Docker credentials, etc.

## Repository Content

- **K8s manifest file**: Directory containing Kubernetes manifest files for use in Cd_server.
- **Terraform file**: Directory containing Terraform configuration files for provisioning resources in the AWS cloud.
- **Images**: Directory containing all the results and errors encountered during the ongoing projects.

### Terraform Execution

1. Initialize Terraform:

   ```bash
   terraform init
### Configure Deployment Instance

- After the t2.medium instance starts, connect to the instance through SSH:
```bash
ssh -i "your_key.pem"  ubuntu@ec2-<ip_address>.ap-northeast-1.compute.amazonaws.com
```

- Inside the Deployment server, run the following commands:

```bash
sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube

sudo snap install kubectl --classic

sudo usermod -aG docker $USER && newgrp docker

minikube start
```

- Copy all the manifest files from your local machine to the instance using **scp protocol**.
-  For that get out of the instance and now run the below command on your local command line interface.

```bash
cd `k8s manifest file`
scp -i /path/to/your/key.pem . ec2-user@<instance-IP>:~/destination/path/
```
- After copying the manifest files to the Deployment server, apply kubectl commands:

```bash
kubectl get all # this will show all the running kubernetes component"

kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

kubectl expose deployment reddit-clone-deployment --type=NodePort

kubectl port-forward svc/reddit-clone-deployment 3000:3000 --address 0.0.0.0 &
```

- The last two commands expose the NodePort of reddit-clone-deployment and bind the container port 3000 to the Deployment server 3000 port.

# Result

- After completing all the mentioned task, open browser and enter **<instance_ip_address>:3000**

![Architecture](https://s3.ap-northeast-1.amazonaws.com/motulaal.io/reddit+project/result_1.png)

- Check inside the Instance using the bash shell.
![Architecture](https://s3.ap-northeast-1.amazonaws.com/motulaal.io/reddit+project/result.png)


## Extras

- To utilize a reverse proxy for your application cluster, apply the ingress.yml file:

```bash
minikube addons enable ingress
```
- To check the current setting for addons in minikube use
```bash
minikube addons list command
```
- Now create ingress for your service.
```bash
kubectl apply -f ingress.yml
```
- Test your ingress using
```bash
curl -L domain/test
```



# Contributors
Your Name @Manish-mech
