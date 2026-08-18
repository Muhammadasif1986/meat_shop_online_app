# AWS Infrastructure for Abdul Ghaffar Meat Shop
# This is a starter template — customize for production use

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"  # Singapore / Mumbai
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "agms-vpc" }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "agms-cluster"
}

# RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier        = "agms-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.medium"
  allocated_storage = 50
  db_name           = "agms"
  username          = "postgres"
  password          = var.db_password
  skip_final_snapshot = true
  backup_retention_period = 7
  multi_az          = false
  tags = { Name = "agms-db" }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "agms-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  tags = { Name = "agms-redis" }
}

# ECR Repository
resource "aws_ecr_repository" "api" {
  name = "agms-api"
  image_scanning_configuration { scan_on_push = true }
}

# ECS Fargate Service (placeholder — expand for production)
# resource "aws_ecs_service" "api" { ... }
