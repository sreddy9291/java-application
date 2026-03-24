Below is a clean, modular Terraform example that creates an AWS S3 bucket with versioning enabled (configurable). The repo is organized into a root module that calls a reusable module located at modules/s3_bucket.

Files provided:
- Root: main.tf, variables.tf, outputs.tf
- Module: modules/s3_bucket/main.tf, modules/s3_bucket/variables.tf, modules/s3_bucket/outputs.tf

Copy these files into your repo with the same paths.

-------------------------
File: main.tf (root)
-------------------------
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_bucket" {
  source = "./modules/s3_bucket"

  bucket_name        = var.bucket_name
  enable_versioning  = var.enable_versioning
  acl                = var.acl
  force_destroy      = var.force_destroy
  tags               = var.tags
}

-------------------------
File: variables.tf (root)
-------------------------
variable "aws_region" {
  description = "AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "enable_versioning" {
  description = "Whether to enable versioning on the S3 bucket."
  type        = bool
  default     = true
}

variable "acl" {
  description = "ACL for the S3 bucket."
  type        = string
  default     = "private"
}

variable "force_destroy" {
  description = "Whether to allow Terraform to destroy the bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

-------------------------
File: outputs.tf (root)
-------------------------
output "bucket_id" {
  description = "The ID of the S3 bucket (same as the bucket name)."
  value       = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = module.s3_bucket.bucket_arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket."
  value       = module.s3_bucket.bucket_domain_name
}

-------------------------
File: modules/s3_bucket/main.tf
-------------------------
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  acl           = var.acl
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name = var.bucket_name
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Optional: output bucket website/domain information depends on provider
# No bucket policy or encryption included here (can be added as needed).

-------------------------
File: modules/s3_bucket/variables.tf
-------------------------
variable "bucket_name" {
  description = "Name of the S3 bucket. Must be globally unique."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }

  # You may want a stricter regex for naming rules; keeping simple validation above.
}

variable "enable_versioning" {
  description = "Whether to enable versioning on the S3 bucket."
  type        = bool
  default     = true
}

variable "acl" {
  description = "Canned ACL to apply to the bucket."
  type        = string
  default     = "private"
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

-------------------------
File: modules/s3_bucket/outputs.tf
-------------------------
output "bucket_id" {
  description = "The bucket name (ID)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

-------------------------
Usage
-------------------------
1. Initialize and apply:
   terraform init
   terraform apply

2. Example override for variables:
   terraform apply -var="bucket_name=my-unique-bucket-name-123" -var="aws_region=us-west-2"

Notes / Best practices suggestions:
- Ensure the bucket_name you supply is globally unique.
- Consider adding server-side encryption (SSE) and bucket policies as required by your security posture.
- For production, configure remote state (e.g., S3 backend + DynamoDB locking).
- Consider lifecycle rules and MFA delete if you require additional protection.

If you want, I can:
- Add server-side encryption and a sample bucket policy.
- Add automated generation of a unique bucket name instead of requiring one.
- Include a backend configuration example for remote state.