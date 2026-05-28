# TechCorp AWS Infrastructure

A Terraform project that provisions a secure, highly available web application infrastructure on AWS.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Guide](#deployment-guide)
- [Accessing the Application](#accessing-the-application)
- [SSH Access Guide](#ssh-access-guide)
- [Destroying the Infrastructure](#destroying-the-infrastructure)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

This project provisions the following AWS resources:

| Resource | Details |
|---|---|
| VPC | CIDR 10.0.0.0/16 with DNS support enabled |
| Subnets | 2 public subnets and 2 private subnets across us-east-1a and us-east-1b |
| Internet Gateway | Attached to the VPC for public internet access |
| NAT Gateways | One per public subnet for outbound internet access from private subnets |
| Bastion Host | EC2 instance in a public subnet for secure SSH access |
| Web Servers | 2 x EC2 instances running Apache in private subnets |
| Database Server | 1 x EC2 instance running PostgreSQL in a private subnet |
| Application Load Balancer | Distributes HTTP traffic across both web servers |
| Security Groups | Separate security groups for bastion, web, and database tiers |

---

## Prerequisites

Before you begin, ensure you have the following installed and configured on your local machine.

### Required tools

**Terraform v1.0 or higher**

Verify your installation:
```bash
terraform --version
```

If not installed, follow the official guide: https://developer.hashicorp.com/terraform/install

---

**AWS CLI v2**

Verify your installation:
```bash
aws --version
```

If not installed, follow the official guide: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

---

**AWS account access**

Configure the AWS CLI with your credentials:
```bash
aws configure
```

You will be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

Verify your credentials are working:
```bash
aws sts get-caller-identity
```

---

**EC2 Key Pair**

You need an EC2 key pair named `techcorp-key` in the `us-east-1` region to SSH into your instances.

Create the key pair and save it to your machine:
```bash
aws ec2 create-key-pair \
  --key-name techcorp-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/techcorp-key.pem
```

Restrict the file permissions so SSH accepts it:
```bash
chmod 400 ~/.ssh/techcorp-key.pem
```

---

**S3 Bucket for Terraform remote state**

This project uses an S3 bucket to store the Terraform state file remotely. Create the bucket before running `terraform init`:

```bash
aws s3api create-bucket \
  --bucket techcorp-terraform-state-YOUR_ACCOUNT_ID \
  --region us-east-1
```

Replace `YOUR_ACCOUNT_ID` with your AWS account ID. You can find it by running:
```bash
aws sts get-caller-identity --query Account --output text
```

Then enable versioning on the bucket:
```bash
aws s3api put-bucket-versioning \
  --bucket techcorp-terraform-state-YOUR_ACCOUNT_ID \
  --versioning-configuration Status=Enabled
```

Once the bucket is created, update the `bucket` value in the `backend "s3"` block inside `main.tf` to match your bucket name.

---

## Project Structure

```
terraform-assessment/
├── main.tf                   # All AWS resource definitions
├── variables.tf              # Variable declarations
├── outputs.tf                # Output values after deployment
├── terraform.tfvars.example  # Example variable values
├── terraform.tfstate         # Terraform state file
├── user_data/
│   ├── web_server_setup.sh   # Apache installation script for web servers
│   └── db_server_setup.sh    # PostgreSQL installation script for database server
├── evidence/                 # Deployment screenshots
└── README.md
```

---

## Deployment Guide

Follow these steps in order to deploy the infrastructure.

### Step 1 — Clone the repository

```bash
git clone https://github.com/fadart/month-one-assessment
cd month-one-assessment
```

---

### Step 2 — Create your variables file

Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` in your editor and fill in your values:
```hcl
region            = "us-east-1"
instance_type_web = "t3.micro"
instance_type_db  = "t3.small"
key_pair_name     = "techcorp-key"
my_ip             = "YOUR_IP_ADDRESS/32"
```

To get your current IP address, run:
```bash
curl ifconfig.me
```

Add `/32` at the end of the IP address. For example, if your IP is `102.89.23.45`, set `my_ip = "102.89.23.45/32"`.

> **Important:** The `terraform.tfvars` file contains your IP address and should never be committed to version control. It is already listed in `.gitignore`.

---

### Step 3 — Initialise Terraform

Download the required AWS provider plugin and configure the remote backend:
```bash
terraform init
```

A successful output ends with:
```
Terraform has been successfully initialized!
```

---

### Step 4 — Validate the configuration

Check for any syntax errors in your Terraform files:
```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

---

### Step 5 — Preview the changes

Generate an execution plan to see exactly what resources will be created before making any changes to AWS:
```bash
terraform plan
```

Review the output carefully. You should see `Plan: 30 to add, 0 to change, 0 to destroy` at the bottom. If the plan looks correct, proceed to the next step.

---

### Step 6 — Deploy the infrastructure

Apply the Terraform configuration to create all resources on AWS:
```bash
terraform apply
```

When prompted, type `yes` to confirm:
```
Do you want to perform these actions?
  Enter a value: yes
```

Deployment takes approximately 5 minutes. NAT Gateways take the longest to provision.

When complete, Terraform prints the following outputs:

```
Outputs:

alb_dns_name      = "techcorp-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com"
bastion_public_ip = "x.x.x.x"
vpc_id            = "vpc-xxxxxxxxxxxxxxxxx"
```

Save these values — you will need them to access the application and SSH into your instances.

---

## Accessing the Application

Once deployment is complete, open your browser and navigate to the ALB DNS name from your Terraform outputs:

```
http://techcorp-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com
```

You should see the TechCorp web page displaying the instance ID of the server that handled your request. Refresh the page a few times — the instance ID will alternate between your two web servers as the load balancer distributes traffic.

> **Note:** Allow 2 to 3 minutes after deployment for the web servers to finish booting and Apache to start before accessing the URL.

---

## SSH Access Guide

All SSH access to private instances must go through the bastion host.

### Connect to the bastion host

From your local machine, use SSH agent forwarding so you can jump to private instances without copying your key:
```bash
ssh-add ~/.ssh/techcorp-key.pem
ssh -A -i ~/.ssh/techcorp-key.pem ec2-user@BASTION_PUBLIC_IP
```

Replace `BASTION_PUBLIC_IP` with the `bastion_public_ip` value from your Terraform outputs.

---

### Connect to a web server from the bastion

Once inside the bastion, SSH into either web server using its private IP:
```bash
ssh ec2-user@WEB_SERVER_PRIVATE_IP
```

To get the private IPs of your web servers, run this from your local machine:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=techcorp-web-server-1" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text
```

---

### Connect to the database server from the bastion

From the bastion, SSH into the database server:
```bash
ssh ec2-user@DB_SERVER_PRIVATE_IP
```

To get the database server private IP:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=techcorp-database-server" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text
```

---

### Connect to PostgreSQL on the database server

Once inside the database server, connect to PostgreSQL:
```bash
sudo -u postgres psql
```

To list all databases:
```bash
\l
```

To exit PostgreSQL:
```bash
\q
```

---

## Destroying the Infrastructure

When you are done with the infrastructure, destroy all resources to avoid ongoing AWS charges.

> **Warning:** This action is irreversible. All resources including EC2 instances, NAT Gateways, and the Load Balancer will be permanently deleted.

Run the destroy command:
```bash
terraform destroy
```

When prompted, type `yes` to confirm:
```
Do you really want to destroy all resources?
  Enter a value: yes
```

Terraform will delete all 30 resources. This takes approximately 5 minutes.

After destroy completes, verify no resources are left running in the AWS Console to ensure you are not being charged.

---

## Troubleshooting

**502 Bad Gateway on the ALB URL**

The web servers may still be booting. Wait 2 to 3 minutes and refresh the page. If the error persists, SSH into a web server and verify Apache is running:
```bash
sudo systemctl status httpd
```

If Apache is not running, start it manually:
```bash
sudo systemctl start httpd
```

---

**SSH connection refused to bastion**

Your IP address may have changed since deployment. Update `my_ip` in `terraform.tfvars` with your current IP and run:
```bash
terraform apply
```

---

**Terraform state errors**

If Terraform reports state errors, ensure your S3 bucket exists and your AWS credentials have read/write access to it:
```bash
aws s3 ls s3://techcorp-terraform-state-YOUR_ACCOUNT_ID
```