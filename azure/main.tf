provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
features {}
}
resource "azurerm_resource_group" "k8s" {
  name     = var.resourcename
  location = var.location
}
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.clustername
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = var.dnspreffix
default_node_pool {
    name       = "default"
    node_count = var.agentnode
    vm_size    = var.size
  }
service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }
}
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  load_config_file = false

  host     = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  username = azurerm_kubernetes_cluster.k8s.kube_config.0.username
  password = azurerm_kubernetes_cluster.k8s.kube_config.0.password

  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)}"
}

resource "azurerm_public_ip" "k8s" {
  name                = "scalable-nginx-public-ip"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }
}
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx"
    labels = {
      App = "ScalableNginx"
    }
  }

  spec {
    replicas = 5
    selector {
      match_labels = {
        App = "ScalableNginx"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginx"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "nginx"

          port {
            container_port = 80
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "nginx" {
  metadata {
    name = "scalable-nginx-service"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
    external_ips = ["52.146.66.198"] # az network public-ip show --resource-group ${resourcegroup} --name ${akspublicipname} --query ipAddress --output tsv

  }
}
