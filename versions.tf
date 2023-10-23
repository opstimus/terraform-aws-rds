terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    external = {
      version = ">= 2.2.0"
    }

    random = {
      version = ">= 3.4.0"
    }

    time = {
      version = "~> 0.9"
    }
  }
}
