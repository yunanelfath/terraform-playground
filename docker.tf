provider "docker" {
  host = "tcp://192.168.44.101:2376/"
}

resource "docker_volume" "nginx_data1" {}
resource "docker_volume" "html_data1" {}

resource "docker_network" "local_net" {
  name = "local_net"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "192.168.55.100:5000/nginx"
  restart = "always"
  network_mode = "local_net"
  volumes {
    container_path = "/usr/share/nginx/html"
    volume_name = "html_data1"
  }
  volumes {
    container_path = "/etc/nginx"
    volume_name = "nginx_data1"
  }
  ports {
    internal = "80"
    external = "80"
  }
}

resource "docker_container" "sftp" {
  name  = "sftp"
  image = "192.168.55.100:5000/sftp"
  network_mode = "local_net"
  command = [ "usernginx:secret123:1001" ]
  ports {
    internal = "22"
    external = "2222"
  }
  volumes {
    container_path = "/home/usernginx/upload/nginx"
    volume_name = "nginx_data1"
  }
  volumes {
    container_path = "/home/usernginx/upload/html"
    volume_name = "html_data1"
  }
}
