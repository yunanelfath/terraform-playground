
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.12"
}

provider "docker" {}


# Generate a keyfile for MongoDB authentication
resource "null_resource" "generate_keyfile" {
  provisioner "local-exec" {
    command = <<EOT
      openssl rand -base64 756 > mongo-keyfile
      chmod 400 mongo-keyfile
    EOT
  }
}


variable "mongo_root_username" {
  default = "admin"
}

variable "mongo_root_password" {
  default = "secret123"
}

resource "docker_image" "mongodb" {
  name = "mongo"
}


resource "docker_container" "mongodb" {
  name    = "mongodb_adminsecret123"
  image   = docker_image.mongodb.image_id
  restart = "always"

  ports {
    internal = "27017"
    external = "27017"
  }
  env = [
    "MONGO_REPLICA_SET_NAME=rs0",
    "MONGO_INITDB_ROOT_USERNAME=${var.mongo_root_username}",
    "MONGO_INITDB_ROOT_PASSWORD=${var.mongo_root_password}"
  ]
  command = [
    "mongod", "--replSet", "rs0",
    "--keyFile", "/etc/mongo-keyfile"
  ]

  volumes {
    container_path = "/data/db"
    host_path      = abspath("${path.module}/db")
  }
  volumes {
    container_path = "/etc/mongo-keyfile"
    host_path      = abspath("${path.module}/mongo-keyfile")  # Convert to absolute path
    read_only      = true
  }
  depends_on = [null_resource.generate_keyfile]
}

# Initialize the Replica Set using a null_resource
resource "null_resource" "init_mongo_replset" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 90
      mongosh --host localhost -u ${var.mongo_root_username} -p ${var.mongo_root_password} --eval 'rs.initiate({_id: "rs0", members: [{ _id: 0, host: "localhost:27017" }]})'
    EOT
  }

  depends_on = [docker_container.mongodb]
}

resource "null_resource" "destroy_mongo_keyfile" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -rf mongo-keyfile
      rm -rf db/* db/.mongodb
    EOT
  }
  depends_on = [docker_container.mongodb]
}
