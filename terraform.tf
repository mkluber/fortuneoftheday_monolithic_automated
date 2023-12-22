terraform {
  cloud {
    organization = "outworldindustries"

    workspaces {
      name = "fortuneoftheday_monolithic_automated"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
  }

  required_version = "~> 1.2"
}
