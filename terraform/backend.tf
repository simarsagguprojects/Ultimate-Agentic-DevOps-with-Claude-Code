# ─── Remote State Backend (S3) ────────────────────────────────────────────────
#
# INSTRUCTIONS — two-step bootstrap:
#
#   Step 1: First-time setup
#     Run `terraform init` and `terraform apply` WITHOUT this backend block enabled.
#     This creates your S3 bucket and other resources using local state.
#
#   Step 2: Migrate state to S3
#     1. Create a dedicated S3 bucket for Terraform state
#        (e.g. "devops-terraform-state-956651462310") and enable versioning on it.
#     2. Uncomment the backend block below and fill in your state bucket name.
#     3. Run `terraform init -migrate-state` — Terraform will copy local state to S3.
#
# After migration all subsequent runs use the remote backend automatically.
# ──────────────────────────────────────────────────────────────────────────────

# terraform {
#   backend "s3" {
#     bucket  = "devops-terraform-state-956651462310"   # replace with your state bucket
#     key     = "portfolio-site/terraform.tfstate"
#     region  = "ap-south-1"
#     encrypt = true
#   }
# }
