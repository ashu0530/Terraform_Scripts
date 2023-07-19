# Terraform Project

This Terraform project provisions infrastructure resources on AWS for a Docker Swarm cluster.

## Prerequisites

Before using this project, ensure that you have the following prerequisites:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials and a profile named in my case "ashu".
- An AWS region to deploy the resources.

## Configuration

1. Clone the repository:

   ```shell
   git clone https://github.com/ashu0530/Terraform_Scripts.git

2. Navigate to the project directory:

   ```shell
   cd Terraform_Scripts

3. Open the variables.tf file and review the default values for the variables. Modify them if needed. Initialize the project

   ```shell
   terraform init

4. Review the execution plan:

   ```shell
   terraform plan

5. Deploy the resources:

   ```shell
   terraform apply

6. Clean up the resources after you are done:

   ```shell
   terraform destroy

## Files
- main.tf: This file contains the main configuration for the Terraform project. It defines the infrastructure resources, including VPC, subnet, security group, key pair, and EC2 instances for the Docker Swarm cluster.

- variables.tf: This file defines the variables used in the Terraform project. It provides flexibility and allows customization of resource properties.

## Architecture
### The Terraform code provisions the following resources:

- VPC: A virtual private cloud (VPC) to isolate the Docker Swarm cluster.
- Subnet: A subnet within the VPC for the EC2 instances.
- Internet Gateway: An internet gateway allowing inbound and outbound internet traffic for the VPC.
- Route Table: A route table that defines the routing for the VPC traffic.
- Route Table Association: An association between the subnet and route table to control the traffic flow.
- Security Group: A security group allowing inbound SSH access and specific ports required for Docker Swarm.
- Key Pair: A key pair used for SSH access to the EC2 instances.
- EC2 Instances: AWS EC2 instances for the Docker Swarm master and worker nodes.
- The architecture ensures the necessary networking components and security configurations for the Docker Swarm cluster.

## Output
### After successfully deploying the resources, the following outputs will be displayed:

- master_ip_public: Public IP address of the Docker Swarm master node.
- master_ip_private: Private IP address of the Docker Swarm master node.
- worker_ip_public: Public IP address of the Docker Swarm worker node.
- worker_ip_private: Private IP address of the Docker Swarm worker node.
   
   


   
   
   

