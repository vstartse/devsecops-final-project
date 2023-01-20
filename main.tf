# Set the AWS region for the project
provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

# Create the VPC
resource "aws_vpc" "final_project_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "final_project_vpc"
  }
}

# Create public subnet for the EC2
resource "aws_subnet" "final_project_subnet" {
  vpc_id            = aws_vpc.final_project_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "final_project_subnet"
  }
}

# Create internet gateway for connection to the internet
resource "aws_internet_gateway" "final_project_ig" {
  vpc_id = aws_vpc.final_project_vpc.id

  tags = {
    Name = "final_project_ig"
  }
}

# Create public route table
resource "aws_route_table" "final_project_public_rt" {
  vpc_id = aws_vpc.final_project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.final_project_ig.id
  }

  tags = {
    Name = "final_project_public_rt"
  }
}

# Create route table association to connect the public subnet to the internet
resource "aws_route_table_association" "final_project_rt_a" {
  subnet_id      = aws_subnet.final_project_subnet.id
  route_table_id = aws_route_table.final_project_public_rt.id
}

# Create security group to apply firewall rules for connectivity
# Open port 22 for inbound SSH connection
# Open port 3000 for inbound application connection
# Set outbound connection to all
resource "aws_security_group" "final_project_sg" {
  name   = "Web and SSH"
  vpc_id = aws_vpc.final_project_vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance from AWS linux AMI
# Use "init.sh" script to configure the instance after creation
# Pay attention - key pair with name "final_project_key_pair" should be
# existed before creating the instance
resource "aws_instance" "final_project_instance" {
  ami           = "ami-0a261c0e5f51090b1"
  instance_type = "t2.micro"
  key_name      = "final_project_key_pair"

  subnet_id                   = aws_subnet.final_project_subnet.id
  vpc_security_group_ids      = [aws_security_group.final_project_sg.id]
  associate_public_ip_address = true

  user_data = "${file("init.sh")}"

  tags = {
    Name = "final_project_instance"
  }
}