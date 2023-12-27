# HERE HERE HERE
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "sparktrade_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sparktrade"
  }
}

resource "aws_internet_gateway" "sparktrade_gateway" {
  vpc_id = aws_vpc.sparktrade_vpc.id
}

resource "aws_subnet" "subnet_2a" {
  vpc_id                  = aws_vpc.sparktrade_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_2a"
  }
}

resource "aws_subnet" "subnet_2b" {
  vpc_id                  = aws_vpc.sparktrade_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_2b"
  }
}

resource "aws_route_table" "sparktrade_route_table" {
  vpc_id = aws_vpc.sparktrade_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sparktrade_gateway.id
  }

  tags = {
    Name = "sparktrade_route_table"
  }
}

resource "aws_route_table_association" "subnet_2a_association" {
  subnet_id      = aws_subnet.subnet_2a.id
  route_table_id = aws_route_table.sparktrade_route_table.id
}

resource "aws_route_table_association" "subnet_2b_association" {
  subnet_id      = aws_subnet.subnet_2b.id
  route_table_id = aws_route_table.sparktrade_route_table.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.sparktrade_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.34.230.163/32"]  # Replace with your IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_db_subnet_group" "rdb_subnet_group" {
  name = "rdb_subnet_group"
  # subnet groups need a minimum of two subnets to create an RDB
  subnet_ids = [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id]

  tags = {
    Name = "rdb_subnet_group"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key)
}

resource "aws_security_group" "rdb_security_group" {
  name        = "rdb_security_group"
  description = "Allow MySQL"
  vpc_id      = aws_vpc.sparktrade_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]  # Allow RDS access only from the EC2 instance security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rdb_security_group"
  }
}

resource "aws_db_instance" "rdb_instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  username               = "dbmaster"
  password               = "dbmasterpassword"
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.rdb_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rdb_security_group.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
  multi_az               = false

  backup_retention_period = 7
  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"

  tags = {
    Name = "rdb_instance"
  }
}

resource "aws_instance" "app_server" {
  # Ubuntu 20.04 ami
  ami                    = "ami-0c0ba4e76e4392ce9"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.subnet_2a.id  # Attach the instance to a public subnet

  tags = {
    Name = "SparkTradeServerInstance"
  }

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu" 
    private_key = file(var.private_key)
    host        = self.public_ip
  }
}
