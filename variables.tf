variable "profile" {
    type        = string
    description = "AWS Profile"
  }

variable "region" {
    type        = string
    description = "AWS Region"
  }

variable "subnet_id" {
  type = list(string)
  default = ["subnet-0664fa2eab9ac6c0c","subnet-05ed8d77a7b1ae78f"]
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami" {
  type    = string
  default = "ami-06c39ed6b42908a36"
}

variable "vpc_security_group_ids" {
  type = set(string)
  default = (["kn-sg-web"])
}

variable "tags" {
  type = map(string)
  default = {}
}
