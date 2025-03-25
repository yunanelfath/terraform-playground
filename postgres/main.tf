
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.12"
}
variable "POSTGRES_PASSWORD" {
  default = "none"
}
provider "docker" {}


resource "docker_container" "postgres_tf" {
  name    = "pg_secret123"
  image   = "postgres"
  restart = "always"

  ports {
    internal = "5432"
    external = "5455"
  }
  env = [
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}",
  ]
}
