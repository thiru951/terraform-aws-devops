terraform {
  backend "s3" {
    bucket         = "terraform-state-thiru-2026"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

