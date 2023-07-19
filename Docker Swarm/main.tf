provider "aws" {
  profile = "ashu"     
  region  =   "us-east-1"    
}

resource "aws_vpc" "docker_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default" 
  tags= {
     Name = "docker-vpc"
   }
}

# Subnet configuration
resource "aws_subnet" "docker_swarm_subnet" {
  vpc_id                  = aws_vpc.docker_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "DockerSwarmSubnet"
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "docker_internet_gateway" {
  vpc_id = "${aws_vpc.docker_vpc.id}"
  tags = {
    Name = "docker-ig"
  }
  depends_on = [
    aws_vpc.docker_vpc, aws_subnet.docker_swarm_subnet
  ]
}

#Create Route Table
resource "aws_route_table" "docker_route_table" {
  vpc_id = "${aws_vpc.docker_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.docker_internet_gateway.id}"
  }
  tags = {
    Name = "docker-route-table"
  }
  depends_on = [
    aws_vpc.docker_vpc, aws_internet_gateway.docker_internet_gateway,
  ]
}

#Create Route Table Association
resource "aws_route_table_association" "docker_rta" {
  subnet_id      = "${aws_subnet.docker_swarm_subnet.id}"
  route_table_id = "${aws_route_table.docker_route_table.id}"
  depends_on = [
    aws_subnet.docker_swarm_subnet, aws_route_table.docker_route_table,

  ]
}


# Security group configuration
resource "aws_security_group" "docker_swarm_sg" {
  name        = "DockerswarmSecurityGroup"
  description = "Security group for Docker Swarm cluster"
  vpc_id      = aws_vpc.docker_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 2377   #TCP for communication with and between manager nodes
    to_port         = 2377
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port       = 4789 #TCP/UDP for overlay network node discovery
    to_port         = 4789
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 4789 #TCP/UDP for overlay network node discovery
    to_port         = 4789
    protocol        = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port       = 7946
    to_port         = 7946
    protocol        = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port       = 7946 #UDP (configurable) for overlay network traffic
    to_port         = 7946
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a key-pair for aws instance for login

#Generate a key using RSA algo
resource "tls_private_key" "instance_key_docker" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#create a key-pair 
resource "aws_key_pair" "key_pair" {
  key_name   = "instance_key_docker"
  public_key = "${tls_private_key.instance_key_docker.public_key_openssh}"
  depends_on = [  tls_private_key.instance_key_docker ]
}

#save the key file locally inside workspace in .pem extension file
resource "local_file" "save_docker_key" {
  content = "${tls_private_key.instance_key_docker.private_key_pem}"
  filename = "instance_key_docker.pem"
  depends_on = [
   tls_private_key.instance_key_docker, aws_key_pair.key_pair ]
}


# EC2 instance configuration
resource "aws_instance" "docker_swarm_master" {
  ami                    = "${var.master_ami}"
  instance_type          = "t2.micro"
  count =                   1
  key_name               =  aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.docker_swarm_sg.id]
  subnet_id              = aws_subnet.docker_swarm_subnet.id







  connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key.instance_key_docker.private_key_pem
      host = self.public_ip
      timeout     = "5m"
    }
provisioner "remote-exec" {
    inline = [
    "sleep 5",
    "sudo apt-get clean",
    "sudo apt-get update",
    "sudo apt-get install -y apt-transport-https ca-certificates nfs-common curl software-properties-common",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"  -y",
    
    "sudo apt-get install -y docker-ce",
    "sudo usermod -aG docker ubuntu",
    "sleep 5",
    "sudo docker swarm init",
    "sudo docker swarm join-token --quiet worker > /home/ubuntu/token",

    ]
  }


//provisioner "local-exec" {
  //  command = "ssh -i instance_key_docker.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${self.public_ip} 'docker swarm join-token -q worker' > token.txt"
  //}
 tags = {
		Name = "docker_master_inst"
	}
}

# EC2 instance configuration worker
resource "aws_instance" "docker_swarm_worker" {
  ami                    = "${var.master_ami}"
  instance_type          = "t2.micro"
  count =                   1
  key_name               =  aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.docker_swarm_sg.id]
  subnet_id              = aws_subnet.docker_swarm_subnet.id







  connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key.instance_key_docker.private_key_pem
      host = self.public_ip
      timeout     = "5m"
    }
provisioner "file" {
    source = "instance_key_docker.pem"
    destination = "/home/ubuntu/instance_key_docker.pem"
  }
provisioner "remote-exec" {
    inline = [
    "sleep 5",
    "sudo apt-get clean",
    "sudo apt-get update",
    "sudo apt-get install -y apt-transport-https ca-certificates nfs-common curl software-properties-common",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"  -y",
    
    "sudo apt-get install -y docker-ce",
    "sudo usermod -aG docker ubuntu",
    "sudo chmod 400 /home/ubuntu/instance_key_docker.pem",
    "sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i instance_key_docker.pem ubuntu@${aws_instance.docker_swarm_master[0].private_ip}:/home/ubuntu/token .",
    "sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.docker_swarm_master[0].private_ip}:2377",
    "sleep 5",

    ]
  }

 tags = {
		Name = "docker_worker_inst"
	}
}

#Output of wordpress public dns
output "master_ip_public" {
  	value = aws_instance.docker_swarm_master.public_ip
}

output "master_ip_private" {
  	value = aws_instance.docker_swarm_master.private_ip
}

output "worker_ip_public" {
  	value = aws_instance.docker_swarm_worker.public_ip
}

output "master_ip_public" {
  	value = aws_instance.docker_swarm_worker.private_ip
}




