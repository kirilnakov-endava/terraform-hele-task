profile                   = "knakov-sandbox"
region                    = "eu-central-1"
subnet_id                 = ["subnet-0664fa2eab9ac6c0c","subnet-05ed8d77a7b1ae78f"]
ami                       = "ami-06c39ed6b42908a36"
instance_type             = "t2.micro"
vpc_security_group_ids    = (["kn-web"])
tags                      = {"name"="kn-ec2-instance1","name"="kn-ec2-instance2"}
vpc_id                    = "vpc-045baf1458325e645"
