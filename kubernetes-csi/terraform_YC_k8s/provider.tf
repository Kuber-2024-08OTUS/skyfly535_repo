# Определение провайдеров
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "~> 0.67.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
  required_version = ">= 0.13"
}
# Провайдер yandex настраивается с использованием ключа сервисного аккаунта
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# Data-сурс для получения конфигурации клиента
data "yandex_client_config" "client" {}

locals {
  # Используем атрибуты созданного кластера Kubernetes
  cluster_endpoint       = yandex_kubernetes_cluster.yc_cluster.master.0.external_v4_endpoint
  cluster_ca_certificate = yandex_kubernetes_cluster.yc_cluster.master.0.cluster_ca_certificate
  # Получаем IAM токен для аутентификации с Kubernetes API
  kubernetes_token       = data.yandex_client_config.client.iam_token
}

# Провайдер Kubernetes для управления ресурсами в кластере
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.kubernetes_token
}

# Провайдер Helm для управления Helm-чартами
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.kubernetes_token
  }
}

# Провайдер Kubectl для выполнения команд kubectl
provider "kubectl" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.kubernetes_token
  load_config_file       = false
}
