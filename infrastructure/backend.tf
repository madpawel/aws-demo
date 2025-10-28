terraform {
  backend "s3" {
    bucket         = "ip-display-app-terraform-state-082484899335"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ip-display-app-terraform-locks"
    encrypt        = true
  }
}
