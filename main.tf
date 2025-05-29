# Create our VPC 

resource "aws_vpc" "KCVPC" {
  cidr_block       = "10.0.0.0/16"
  #instance_tenancy = "default"

  tags = {
    Name = "MideVPCxyz"
  }
}

# Create the public subnet

resource "aws_subnet" "PublicSubnet" {
  vpc_id     = aws_vpc.KCVPC.id 
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PublicSubnet"
  }
}


# Create the private subnet

resource "aws_subnet" "PrivateSubnet" {
  vpc_id     = aws_vpc.KCVPC.id 
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrivateSubnet"
  }
}


# Create an internet gateway 

resource "aws_internet_gateway" "KCIGW" {
  vpc_id = aws_vpc.KCVPC.id

  tags = {
    Name = "KCIGW"
  }
}


# Create the public route table

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.KCVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.KCIGW.id
  }


  tags = {
    Name = "PublicRT"
  }
}

# Associate the public subnet to the public route table

resource "aws_route_table_association" "PublicRTA" {
  subnet_id      = aws_subnet.PublicSubnet.id 
  route_table_id = aws_route_table.PublicRT.id
}


# Create the private route table

resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.KCVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "aws_nat_gateway.KCNATGW.id"
  }


  tags = {
    Name = "PrivateRT"
  }
}

# Associate the private subnet to the private route table

resource "aws_route_table_association" "PrivateRTA" {
  subnet_id      = aws_subnet.PrivateSubnet.id 
  route_table_id = aws_route_table.PrivateRT.id
}


# create an elastic ip

resource "aws_eip" "KCEIP" {
  #instance = aws_instance.web.id
  domain   = "vpc"
}


# Create the NAT gateway 

resource "aws_nat_gateway" "KCNATGW" {
  allocation_id = aws_eip.KCEIP.id
  subnet_id     = aws_subnet.PublicSubnet.id

  tags = {
    Name = "KCNATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.KCIGW]
}

# Create security group for public instances 

resource "aws_security_group" "PublicSG" {
  name        = "PublicSG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.KCVPC.id

  tags = {
    Name = "PublicSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTPS" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# Create security group for private instances 

resource "aws_security_group" "PrivateSG" {
  name        = "PrivateSG"
  description = "Allow specific traffic to run"
  vpc_id      = aws_vpc.KCVPC.id

  tags = {
    Name = "PrivateSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_Postgresql_traffic" {
  security_group_id = aws_security_group.PrivateSG.id
  cidr_ipv4         = "10.0.1.0/24"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_out" {
  security_group_id = aws_security_group.PrivateSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create a keypair 

resource "aws_key_pair" "mide-keypair2" {
  key_name   = "mide-keypair2"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6sv7hRGuUSp+fRlE+LdruJCjWJpOzuo6I8kud/w7pV BD_Medsaf@OluwaJT"
}

# create an ec2 instance

resource "aws_instance" "webserver" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PublicSubnet.id
  vpc_security_group_ids = [aws_security_group.PublicSG.id]
  key_name = "mide-keypair2"
  availability_zone = "us-east-1a"
  associate_public_ip_address = "true" 


  tags = {
    Name = "webserver"
  }
}
