provider "aws" {
  region = "us-east-1"
  profile = "personal-aws"
}

resource "aws_vpc" "procat-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    name = "procat-vpc"
  }
}

resource "aws_subnet" "subnet_public_1" {
    vpc_id = aws_vpc.procat-vpc.id
    cidr_block = cidrsubnet(aws_vpc.procat-vpc.cidr_block, 8, 1)
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
      name = "procat-subnet-public-1"
    }
}
resource "aws_subnet" "subnet_public_2" {
    vpc_id = aws_vpc.procat-vpc.id
    cidr_block = cidrsubnet(aws_vpc.procat-vpc.cidr_block, 8, 2)
    map_public_ip_on_launch = true
    availability_zone = "us-east-1b"
    tags = {
      name = "procat-subnet-public-2"
    }
}

resource "aws_internet_gateway" "procat-igw" {
  vpc_id = aws_vpc.procat-vpc.id
  depends_on = [
    aws_vpc.procat-vpc
  ]
  tags = {
    name = "procat-igw"
  }
}

resource "aws_route_table" "procat_route_table" {
  vpc_id = aws_vpc.procat-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.procat-igw.id
}
depends_on = [
    aws_internet_gateway.procat-igw
  ]
tags = {
  name = "procat-route-table"
}
}

resource "aws_route_table_association" "subnet_public_1_route" {
  subnet_id = aws_subnet.subnet_public_1.id
  route_table_id = aws_route_table.procat_route_table.id
}

resource "aws_route_table_association" "subnet_public_2_route" {
  subnet_id = aws_subnet.subnet_public_2.id
  route_table_id = aws_route_table.procat_route_table.id
}

resource "aws_security_group" "cluster_sg" {
    name = "ecs_cluster_sg"
    vpc_id = aws_vpc.procat-vpc.id

    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        self = false
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all inbound traffic"
    }   

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
