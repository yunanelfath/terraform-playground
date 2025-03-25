
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.12"
}

provider "docker" {}
resource "docker_network" "custom_network" {
  name   = "application"
  driver = "bridge"

  ipam_config {
    subnet  = "10.0.100.0/24"
    gateway = "10.0.100.1"
  }
}
