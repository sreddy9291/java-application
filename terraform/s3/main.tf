Below is a clean, modular Terraform configuration that creates an AWS S3 bucket with versioning enabled. The root module calls a reusable module located in modules/s3-bucket. Files provided:

- Root:
  - main.tf
  - variables.tf
  - outputs.tf
- Module (modules/s3-bucket):
  - main.tf
  - variables.tf
  - outputs.tf

Adjust variables (bucket_name, region, tags, etc.) as needed.

Root: main.tf
```
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_bucket" {
  source = "./modules/s3-bucket"

  bucket_name         = var.bucket_name
  tags                = var.tags
  versioning_enabled  = var.versioning_enabled
  force_destroy       = var.force_destroy
}
```

Root: variables.tf
```
variable "aws_region" {
  description = "AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create. Must be globally unique."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Whether to enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "When true, the bucket will be destroyed even if it contains objects."
  type        = bool
  default     = false
}
```

Root: outputs.tf
```
output "bucket_id" {
  description = "The name (ID) of the S3 bucket."
  value       = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = module.s3_bucket.bucket_arn
}
```

Module: modules/s3-bucket/main.tf
```
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = var.force_destroy
  tags          = var.tags

  versioning {
    enabled = var.versioning_enabled
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default server-side encryption (SSE-S3). Optional but recommended.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

Module: modules/s3-bucket/variables.tf
```
variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Whether to enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket when it contains objects."
  type        = bool
  default     = false
}
```

Module: modules/s3-bucket/outputs.tf
```
output "bucket_id" {
  description = "S3 bucket name (ID)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.this.arn
}
```

Usage notes:
- Provide a globally unique bucket name when running (set var.bucket_name).
- If you want Terraform to delete non-empty buckets on destroy, set force_destroy = true.
- Versioning is enabled by default in this example; change var.versioning_enabled if needed.
- You can expand the module to include lifecycle rules, logging, replication, or a policy as required.