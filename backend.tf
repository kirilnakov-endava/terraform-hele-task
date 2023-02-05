terraform {
  backend "s3" {
    bucket         = "kn-terraform-state-bucket-1"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "kn-terraform-state-lock"
  }
}
