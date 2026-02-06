provider "aws" {
  region = "ap-south-1" # AWS CLI credentials will be used
}

# VPC + Subnets + IGW
resource "aws_vpc" "vpc" { cidr_block = "10.0.0.0/16" }
resource "aws_subnet" "subnet1" { vpc_id = aws_vpc.vpc.id, cidr_block = "10.0.1.0/24" }
resource "aws_subnet" "subnet2" { vpc_id = aws_vpc.vpc.id, cidr_block = "10.0.2.0/24" }
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.vpc.id }

# Security Group
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
  ingress { from_port=0, to_port=0, protocol="-1", cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0, to_port=0, protocol="-1", cidr_blocks=["0.0.0.0/0"] }
}

# ECR repository
resource "aws_ecr_repository" "ecr" { name = "my-app" }

# EKS cluster with 2 nodes
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "devops-eks"
  cluster_version = "1.29"
  vpc_id          = aws_vpc.vpc.id
  subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  cluster_security_group_id = aws_security_group.sg.id
  node_groups = {
    devops_nodes = {
      desired_capacity = 2
      max_capacity     = 2
      min_capacity     = 1
      instance_type    = "t3.micro" # Free-tier
    }
  }
}

# EFS shared storage
resource "aws_efs_file_system" "efs" {}
resource "aws_efs_mount_target" "mt1" { file_system_id = aws_efs_file_system.efs.id, subnet_id = aws_subnet.subnet1.id, security_groups=[aws_security_group.sg.id] }
resource "aws_efs_mount_target" "mt2" { file_system_id = aws_efs_file_system.efs.id, subnet_id = aws_subnet.subnet2.id, security_groups=[aws_security_group.sg.id] }

