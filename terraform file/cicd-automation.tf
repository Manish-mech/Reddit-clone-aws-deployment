# main.tf

provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    name = "reddit-clone"
  }
}

resource "aws_subnet" "rc_pub" {
  depends_on            = [aws_vpc.vpc]
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.subnet_cidr_block
  map_public_ip_on_launch = true
  tags = {
    name = "rc_pub_subnet"
  }
}

resource "aws_internet_gateway" "rc_igw" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  tags       = {
    name = "rc_igw"
  }
}

resource "aws_route_table" "rc_rt" {
  depends_on = [aws_internet_gateway.rc_igw]
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rc_igw.id
  }
  tags = {
    name = "rc_rt"
  }
}

resource "aws_route_table_association" "rc_rta" {
  depends_on     = [aws_subnet.rc_pub, aws_route_table.rc_rt]
  subnet_id      = aws_subnet.rc_pub.id
  route_table_id = aws_route_table.rc_rt.id
}

resource "aws_security_group" "ci_instance_sg" {
  name        = "ci_instance_securitygp"
  description = "Allow inbound SSH; Allow outbound internet access for package installation and Docker"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr_block] # Allow SSH access from anywhere
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow outbound traffic to the internet"
  }
}

resource "aws_instance" "ci_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_ci
  key_name               = "new-tier"
  vpc_security_group_ids = [aws_security_group.ci_instance_sg.id]
  subnet_id              = aws_subnet.rc_pub.id

  tags = {
    Name = "ci_instance"
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    git clone https://github.com/LondheShubham153/reddit-clone-k8s-ingress.git
    cd reddit-clone-k8s-ingress/
    sudo docker build -t ${var.docker_username}/reddit_clone_12 .
    echo "${var.docker_password}" | docker login --username "${var.docker_username}" --password-stdin
    docker images
    sudo docker push ${var.docker_username}/reddit_clone_12:latest
    sudo usermod -aG docker $USER && newgrp docker
  EOF
}

resource "aws_security_group" "cd_instance_sg" {
  name        = "cd_instance_sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Deployment instance is public over the internet"

  ingress {
    description = "SSH"
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr_block]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr_block]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.https_cidr_block]
  }

  # Additional ingress rule for port 3000
  ingress {
    description = "Custom port for your application"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust CIDR block as per your requirements
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "cd_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_cd
  key_name               = "your_key"
  vpc_security_group_ids = [aws_security_group.cd_instance_sg.id]
  subnet_id              = aws_subnet.rc_pub.id

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
  EOF

  tags = {
    Name = "cd_instance"
  }
}
