# terraform-hele-task

Apologies for the messy blocks, I would have tried and done those in a more clean fashion.

## Backend.tf

I decided to set the state file to be stored in an S3 bucket instead of local as it is a better practice in most cases

## ELB and why I've used ALB instead
I'd like to point out, that I have tried using an ELB for the load balancer, but there was some issue with getting the EC2 instances to show up as healthy even though they had connectivity and the ELB url have been timing out.I'm probably doing something wrong. So I decided to use an ALB which seems to work at the point of creation.

## Subets, routes & IGW/NAT
I have created a total of 4 subnets, two public, two private with behind the private being the two EC2 instances connecting to the internet via NAT gateway with an Elastic IP. I have also created for testing purposes a bastion host on the public subnets with an assigned public IP (Manually created) to test the connectivity on the EC2 instances.

## Security Group
I have created two security groups. One default for allowing HTTP and SSH traffic to the instances which the ALB is also using and one SG for the RDS instance.

## EC2 instance
Initially I wanted to use custom modules on the ec2 but it became difficult due to the "count" argument being incorporated with the other resources so I used resource block for the EC2. I have used provisioner block and connection block in the resource block, but I have stepped into some errors in the creation of it so I had done those steps manually. Mainly the issue I had was with the count.index in regars to the connection block "host" part as it created a cycle error
