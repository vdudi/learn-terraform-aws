terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

# 1. Create a VPC
# 2. Create Internet Gateway
# 3. Create Custom Route Table
# 4. Create a Subnet
# 5. Associate subnet with Route Table
# 6. Create Security Group to allow port, 22, 80, 443
# 7. Create a network interface with an ip in the subnet that was created in step 4
# 8. Assign an elastic IP to the network interface created in step 7
# 9. Create redhat server and install/enable apache




# 1. Create a VPC
resource "aws_vpc" "dev_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Dev_main"
  }
}
# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dev_main.id

  tags = {
    Name = "Dev_main"
  }
}
# 3. Create Custom Route Table
resource "aws_route_table" "dev_main" {
  vpc_id = aws_vpc.dev_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "dev_main"
  }
}
# 4. Create a Subnet
resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.dev_main.id
  availability_zone = "us-west-2a"
  tags = {
    Name = "dev-subnet"
  }
}
# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.dev_main.id
}
# 6. Create Security Group to allow port, 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web_traffic inbound traffic"
  vpc_id      = aws_vpc.dev_main.id

  ingress {
    description      = "HTTPs"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "lb" {
  instance = aws_instance.webserver.id
  network_interface = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  vpc      = true
  depends_on = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.lb.public_ip
}

# 9. Create redhat server and install/enable apache

resource "aws_instance" "webserver" {
  ami           = "ami-0892d3c7ee96c0bf7"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name = "main-key"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo bash -c 'echo Hello from EC2 apache  > /var/www/html/index.html'
              sudo systemctl start apache2
              EOF

  tags = {
    Name = "web server"
  }
}