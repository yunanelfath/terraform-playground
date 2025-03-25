
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.12"
}

provider "docker" {}

resource "random_password" "redis_password" {
  length  = 16
  special = false
}

resource "docker_container" "redis" {
  name  = "redis_container"
  image = "redis:latest"

  env = [
    "REDIS_PASSWORD=${random_password.redis_password.result}",
    "REDIS_PORT=6379"
  ]

  ports {
    internal = 6379
    external = 6379
  }

  volumes {
    container_path = "/data"
    host_path      = abspath("${path.module}/data")
  }

  networks_advanced {
    name         = "application_network"
    ipv4_address = "10.0.5.4"
  }

  command = ["redis-server", "--requirepass", random_password.redis_password.result]
}

output "redis_password" {
  value     = random_password.redis_password.result
  sensitive = true
}

# Initialize the Replica Set using a null_resource
resource "null_resource" "init_show_redis_password" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 4
      terraform output -raw redis_password
    EOT
  }

  depends_on = [docker_container.redis]
}
