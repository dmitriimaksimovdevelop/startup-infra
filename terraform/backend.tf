terraform {
  backend "s3" {
    # Update the bucket name to match your S3 bucket
    bucket = "your-tfstate-bucket"
    key    = "terraform.tfstate"

    # Hetzner Object Storage endpoint -- update location if needed
    endpoints = {
      s3 = "https://nbg1.your-objectstorage.com"
    }
    region = "nbg1"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
