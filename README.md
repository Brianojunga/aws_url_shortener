# URL Shortener (AWS + Terraform)

A simple URL shortening service built on AWS using Terraform for infrastructure provisioning. The service exposes a REST API backed by an AWS Lambda function and a DynamoDB table. CloudFront sits in front of API Gateway to provide a stable public endpoint and caching.

## 🚀 What this project includes

- **Github Actions** this provisions and destroys the AWS resources through CI/CD
- **AWS Lambda** (`service/handler.py`) to generate short codes and store mappings in DynamoDB
- **DynamoDB table** (`URLShortener`) to persist short code → long URL mappings
- **API Gateway** to expose a REST API (`POST /shorten`, `GET /{shortCode}`)
- **CloudFront distribution** in front of API Gateway for a stable public URL
- **Terraform modules** under `modules/` for clean separation of concerns


## 📁 Repository structure

```
.github/workflow/
  provision.yml  # Provisioning resources through CI/CD
  destroy.yml # Destroying provisioned resources with CI/CD (Github Actions)
modules/
  api_gateway/   # API Gateway + CORS + usage plan
  cloudfront/    # CloudFront distribution in front of API Gateway
  dynamo/        # DynamoDB table
  lambda/        # Lambda function + IAM role
service/         # Lambda source code
terraform/       # Root Terraform config (provider, module wiring, outputs)
```

## ✅ How it works (high level)

1. A client calls **POST /shorten** (via CloudFront URL).
2. Lambda generates a 6-character short code and stores it in DynamoDB.
3. The Lambda response includes the generated short code.
4. A client uses **GET /{shortCode}** (via CloudFront URL) to be redirected to the original URL.

## 🧩 Deploy (Terraform)

### Prerequisites

- AWS CLI configured with credentials and a default region (this project uses `us-east-1` by default)
- Terraform installed (>= 1.0)

### Deploy steps

```bash
cd terraform
terraform init
terraform apply
```

> After a successful run, Terraform will output a CloudFront domain like:
> 
> `https://<cloudfront-id>.cloudfront.net`

## 🔍 Using the API

### Create a short URL

```bash
curl -X POST "https://<cloudfront-domain>/shorten" \
  -H "Content-Type: application/json" \
  -d '{"original_url": "https://example.com"}'
```

Response:

```json
{ "short_code": "Ab12Cd" }
```

### Redirect via short code

```bash
curl -v "https://<cloudfront-domain>/Ab12Cd"
```

The service responds with a `301` redirect to the original long URL.

## 🧪 Local development / testing

Currently, this project is designed to deploy on AWS. The Lambda handler is a simple Python function and can be invoked locally with a test event (e.g., using AWS SAM or unit test harness) if desired.

## 📌 Notes

- The short code generator uses a simple `random.choice`. Collisions are possible and are not currently guarded against.
- There is no authentication or rate limiting beyond the API Gateway usage plan.
- URL validation is not performed before storing the mapping.

