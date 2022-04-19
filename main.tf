terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

### Variables

variable "public-subnet" {
    description = "(list) default gateway subnet to include all ip addresses for ipv4 and ipv6"
    type = list
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "your AWS access key goes here."
  secret_key = "your AWS secret key goes here."
}

#Creating a VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  }

}

#Creating the internet gateway
resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "main"
  }
}

#Redirecting the traffic through the internet
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = var.public-subnet[0]
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  route {
    ipv6_cidr_block = var.public-subnet[1]
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  tags = {
    Name = "production"
  }
}

# Creating the subnet
resource "aws_subnet" "prod-subnet" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "production"
    }
}

# Associating the subnet with a route table 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-route-table.id
}

#Creating security group policies
resource "aws_security_group" "allow_web_group" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.public-subnet[0]]
    ipv6_cidr_blocks = [var.public-subnet[1]]
  }

    ingress {
    description      = "HTTP traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.public-subnet[0]]
    ipv6_cidr_blocks = [var.public-subnet[1]]
  }

    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.public-subnet[0]]
    ipv6_cidr_blocks = [var.public-subnet[1]]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.public-subnet[0]]
    ipv6_cidr_blocks = [var.public-subnet[1]]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}

#Network Interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_group.id]

  
}

#Assigning elastic IP address (note: make sure that depends_on the internet gateway is specified, as its required to exist prior this step).
resource "aws_eip" "prod-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.prod-gw] ### passing as a list, since its required and you can pass as many things as you need.
}

#Show public IP at the end of $terraform plan/apply
output "server_public_ip" {
    value = aws_eip.prod-eip.public_ip
}

#Show private IP at the end of $terraform plan/apply
output "server_private_ip" {
    value = aws_instance.prod-instance.private_ip
}

#Creating ubuntu server 
resource "aws_instance" "prod-instance" {
  ami           = "ami-0e472ba40eb589f49"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  # Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#network-interfaces
  network_interface {
    device_index = 0
    network_interface_id =  aws_network_interface.web-server-nic.id
  }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Your very first web server, now in terraform! > /var/www/html/index.html'
                EOF


  tags = {
    Name = "web-server"
  }
}