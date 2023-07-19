

#Creating Variable For Our Resources
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default = "10.0.0.0/24"
}


variable "master_ami" {
  description = "master ami id"
  default = "ami-053b0d53c279acc90"
}

variable "slave_ami_id" {
  description = "slave ami id"
  default = "ami-053b0d53c279acc90"
}

variable "instance_type" {
  description = "Type for AWS EC2 instance"
  default = "t2.micro"
}



