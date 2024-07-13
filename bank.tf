provider "aws" {
  region     = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "tfvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "tfsub" {
  vpc_id     = aws_vpc.tfvpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "terraform-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "tfgat" {
  vpc_id = aws_vpc.tfvpc.id
  tags = {
    Name = "terraform-igateway"
  }
}

# Route Table
resource "aws_route_table" "tfrt" {
  vpc_id = aws_vpc.tfvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfgat.id
  }

  tags = {
    Name = "terraform-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.tfsub.id
  route_table_id = aws_route_table.tfrt.id
}

# Create Security Group
resource "aws_security_group" "tfs" {
  vpc_id = aws_vpc.tfvpc.id

  ingress {
    description = "All traffic all"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All traffic on port 5439"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 0
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-sg"
  }
}

# Create Network Interface
resource "aws_network_interface" "nwi" {
  subnet_id       = aws_subnet.tfsub.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.tfs.id]
}

# Attaching Elastic IP
resource "aws_eip" "eip" {
  network_interface            = aws_network_interface.nwi.id
  associate_with_private_ip    = "10.0.1.10"  

  depends_on = [aws_instance.banking_project]  
}

# Create AWS Instance
resource "aws_instance" "banking_project" {
  ami                 = "ami-0c2af51e265bd5e0e"
  instance_type      = "t2.medium"
  key_name           = "SA-projectkeypair"

  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.nwi.id
  }

  tags = {
    Name = "banking-build-server"
  }
}
