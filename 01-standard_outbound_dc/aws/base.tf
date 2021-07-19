provider "aws" {
  region     = "ap-southeast-2"
  profile    = "terraform"
}

### Set up the VPCs - Prod, Dev and Shared  ### 
resource "aws_vpc" "prod" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    environment = "study" 
  }
}

### Set Up Route Tables and associations ###
resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.prod.id

  tags = {
    environment = "study"
  }
}

resource "aws_main_route_table_association" "prod" {
  vpc_id         = aws_vpc.prod.id
  route_table_id = aws_route_table.prod.id
}

### Subnets ###
# Two subnets 
resource "aws_subnet" "prod_a" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "10.0.0.0/24"

  tags = {
    environment = "study"
  }
}

resource "aws_subnet" "prod_b" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "10.0.1.0/24"

  tags = {
    environment = "study"
  }
}


### Internet Gateway ###
resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id

  tags = {
    environment = "study"
  }
}

### Routes ###
#resource "aws_route" "prod_default" {
#  route_table_id = aws_route_table.prod.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id = aws_internet_gateway.prod.id
#}
