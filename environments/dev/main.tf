terraform {
    backend "s3" {
        bucket = "s3-tf-state-mds-2026"
        key = "dev/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "dybamo-tfstate-mds-2026"
        encrypt = true
    }
}

provider "aws" {
    region = "us-east-1"
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "s3-tf-state-mds-2026"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = "dynamo-tfstate-mds-2026"
  hash_key = "LockID"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}