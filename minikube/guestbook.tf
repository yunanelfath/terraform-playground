provider "kubernetes" {
  config_context_cluster   = "minikube"
}


resource "kubernetes_deployment" "redisMasterTf" {
  metadata {
    name = "redis-master-tf"
    labels = {
      app = "redis"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis"
        role = "master"
        tier = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis"
          role = "master"
          tier = "backend"
        }
      }

      spec {
        container {
          name = "master"
          image = "192.168.66.100:5000/redis:e2e"
          resources {
            requests {
              cpu = "100m"
              memory = "100Mi"
            }
          }
          port {
            container_port = 6379
          }
        }
      }
    }
  }
}
