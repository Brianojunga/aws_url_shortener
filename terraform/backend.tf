terraform {
  backend "s3"{
    bucket = "s3-bucket-backends-99090009"
    key = "s3CDN/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "dynamo_db_backends_0000100"
    use_lockfile = true
  }
}