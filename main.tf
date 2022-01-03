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

#resource "aws_instance" "example" {
#  ami           = "ami-830c94e3"
#  instance_type = "t2.micro"
#
#  tags = {
#    Name = "ExampleInstance"
#  }
#}

resource "aws_vpc" "dev_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Dev"
  }
}

resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.0.0/24"
  vpc_id     = aws_vpc.dev_main.id

  tags = {
    Name = "dev-subnet"
  }
}
