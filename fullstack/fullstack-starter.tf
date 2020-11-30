provider "kubernetes" {
  config_context_cluster   = "minikube"
}

resource "kubernetes_deployment" "fullstack" {
  metadata {
    name = "fullstack"
    labels = {
      app = "fullstack"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "fullstack"
        tier = "frontendbackend"
      }
    }
    template {
      metadata {
        labels = {
          app = "fullstack"
          tier = "frontendbackend"
        }
      }

      spec {
        container {
          name = "master"
          image = "192.168.66.100:5000/fullstack-starter:v2"
          resources {
            requests {
              cpu = "100m"
              memory = "100Mi"
            }
          }
          port {
            container_port = 3000
          }
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "fullstack" {
  metadata {
    name = "${kubernetes_deployment.fullstack.metadata.0.name}"
    labels = {
      app = "fullstack"
      tier = "frontendbackend"
    }
  }
  spec {
    type = "NodePort"
    # name = "fullstack-starter"
    selector = {
      app = "${kubernetes_deployment.fullstack.metadata.0.name}"
      tier = "frontendbackend"
    }
    port {
      port = 3000
      name = "frontend"
    }
    port {
      port = 5000
      name = "backend"
    }
  }
}

resource "kubernetes_ingress" "fullstack" {
  metadata {
    name = "fullstack"
  }

  spec {

    rule {
      host = "hello-world.info"
      http {
        path {
          backend {
            service_name = "${kubernetes_service.fullstack.metadata.0.name}"
            service_port = 3000
          }

          path = "/fe"
        }

        path {
          backend {
            service_name = "${kubernetes_service.fullstack.metadata.0.name}"
            service_port = 5000
          }

          path = "/api"
        }
      }
    }

  }
}
