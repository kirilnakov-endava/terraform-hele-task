#### S3 Bucket and Dynamodb lock for setting Terraform state file in AWS S3 ####
/*
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "kn-terraform-state-bucket-1"
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "kn-terraform-state-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
}
*/

###############################################################################
### VPC ###

resource "aws_vpc" "knakov-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "knakov-vpc"
  }
}
### SUBNET ###
data "aws_availability_zones" "available" {}

resource "aws_subnet" "knakov-subnet" {
  count      = 2
  vpc_id     = aws_vpc.knakov-vpc.id
  cidr_block = "10.0.${count.index + 1}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "kn-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "kn_public_subnet" {
  count = 2
  vpc_id     = aws_vpc.knakov-vpc.id
  cidr_block = "10.0.${10 + count.index + 1}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "public-${count.index + 1}"
  }
}
### Internet Gateway ###
resource "aws_internet_gateway" "kn-internet_gateway" {
  vpc_id = aws_vpc.knakov-vpc.id
}

### Route table ###
resource "aws_route_table" "kn_route_table" {
  vpc_id = aws_vpc.knakov-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kn-internet_gateway.id
  }
}

### Route table association ### 
resource "aws_route_table_association" "kn-route_table_association" {
  count = 2
  subnet_id      = aws_subnet.kn_public_subnet[count.index].id
  route_table_id = aws_route_table.kn_route_table.id
}

### NAT Gateways and Route table association for the private subnets ###

resource "aws_nat_gateway" "kn-nat-gateway" {
count = 2
allocation_id = aws_eip.kn-nat-eip[count.index].id
subnet_id = aws_subnet.knakov-subnet[count.index].id
tags = {
Name = "kn-nat-gateway-${count.index + 1}"
}
}

resource "aws_eip" "kn-nat-eip" {
count = 2
vpc = true
tags = {
Name = "kn-nat-eip-${count.index + 1}"
}
}

resource "aws_route_table" "kn_private_route_table" {
count = 2
vpc_id = aws_vpc.knakov-vpc.id

route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.kn-nat-gateway[count.index].id
}
}

resource "aws_route_table_association" "kn-private-route-table-association" {
count = 2
subnet_id = aws_subnet.knakov-subnet[count.index].id
route_table_id = aws_route_table.kn_private_route_table[count.index].id
}

### Security Group ###

resource "aws_security_group" "kn-web" {
  name        = "kn-sg-web"
  description = "Allow HTTP and SSH access"
  vpc_id = aws_vpc.knakov-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}

### RDS Instance ###

resource "aws_db_subnet_group" "kn-db-subnet-grp" {
  name = "kn-db-subnet-group"
  subnet_ids = aws_subnet.knakov-subnet.*.id
}

resource "aws_security_group" "kn-rds" {
  name        = "kn-sg-rds"
  description = "Allow RDS access"
  vpc_id = aws_vpc.knakov-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.kn-web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "kn-db" {
  db_name                   = "knwebappdb"
  identifier                = "db"
  allocated_storage         = 10
  instance_class            = "db.t3.micro"
  engine                    = "MySQL"
  engine_version            = "8.0"
  username                  = "admin1"
  password                  = "password1"
  db_subnet_group_name      = "kn-db-subnet-group"
  vpc_security_group_ids    = [aws_security_group.kn-rds.id]
  storage_encrypted         = true
  publicly_accessible       = false
}

### EC2 Instance ###
/*module "kn_ec2" {
  source = "./kn_ec2_module"
  instance_type = "t2.micro"
  ami = "ami-06c39ed6b42908a36"
  vpc_security_group_ids = [aws_security_group.kn-web.id]
  subnet_id = var.subnet_id[count.index]
  tags = {
    Name = "kn-web-app-${count.index + 1}"
  }
  count = 2
  
}
*/

resource "aws_instance" "web_server" {
  count = 2
  associate_public_ip_address = false
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.kn-web.id]
  subnet_id              = var.subnet_id[count.index]
  tags                   = var.tags
  key_name               = "knakov_ec2"
}




### Output for the instance id so it can be used for attaching the EC2 instances to the ELB. ###
### It is good to have a separate outputs.tf file for outputs, but since its just one, i'm not doing it ###

### AWS Elastic Load Balancer ###
resource "aws_elb" "kn-elb" {
  name               = "kn-simple-elb"
  //availability_zones = ["eu-central-1a", "eu-central-1b"]
  subnets     = [aws_subnet.knakov-subnet[0].id, aws_subnet.knakov-subnet[1].id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

resource "aws_elb_attachment" "kn-elb-attach-ec2" {
  count = 2
  elb      = aws_elb.kn-elb.name
  instance = aws_instance.web_server[count.index].id
}
### EFS storage ###

resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "efs-shared-storage"

  tags = {
    Name = "kn-EFS-storage"
  }
}



### Cloudwatch alarm ### 

resource "aws_cloudwatch_metric_alarm" "kn_cloudwatch_alarm" {
  alarm_name          = "kn_simple_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TotalRequests"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "SampleCount"
  threshold           = 2
  alarm_description   = "This metric checks the total number of requests to the Application ELB"
  alarm_actions       = [aws_sns_topic.kn_sns_topic.arn]
  dimensions = {
    LoadBalancer = aws_elb.kn-elb.name
  }
}

resource "aws_sns_topic" "kn_sns_topic" {
  name = "kn-simple-sns-topic"
}