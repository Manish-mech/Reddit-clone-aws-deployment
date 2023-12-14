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
  key_name               = "new-tier"
  vpc_security_group_ids = [aws_security_group.cd_instance_sg.id]
  subnet_id              = aws_subnet.rc_pub.id

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    sudo snap install kubectl --classic
    sudo usermod -aG docker $USER && newgrp docker
    minikube start

    cat <<'EOT' > deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: reddit-clone-deployment
    labels:
        app: reddit-clone
    spec:
    replicas: 2
    selector:
        matchLabels:
         app: reddit-clone
    template:
        metadata:
            labels:
                app: reddit-clone
        spec:
            containers:
            - name: reddit-clone
              image: ${var.docker_username}/reddit_clone
              ports:
                - containerPort: 3000
    EOT

    kubectl apply -f deployment.yaml

    cat <<'EOT' > service.yaml
    apiVersion: v1
    kind: Service
    metadata:
        name: reddit-service
        labels:
            app: reddit-clone
    spec:
        selector:
            app: reddit-clone
        type: NodePort
        ports:
        - port: 3000
          targetPort: 3000
          nodePort: 31000
    EOT

    kubectl apply -f service.yaml

    kubectl expose deployment reddit-clone-deployment --type=NodePort
    kubectl port-forward svc/reddit-clone-deployment 3000:3000 --address 0.0.0.0 &
  EOF

  tags = {
    Name = "cd_instance"
  }
}
