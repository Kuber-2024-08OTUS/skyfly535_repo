# Создание сервисного аккаунта 
resource "yandex_iam_service_account" "otus_sa" {
  name = var.service_account_name
}
# Назначение IAM ролей
resource "yandex_resourcemanager_folder_iam_member" "otus_sa_roles" {
  for_each = toset([
    "editor",
    "storage.admin",
    "container-registry.images.puller",
    "container-registry.images.pusher"
  ])

  role      = each.value
  folder_id = var.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.otus_sa.id}"
  depends_on = [yandex_iam_service_account.otus_sa]
}


# Создание Kubernetes-кластера
resource "yandex_kubernetes_cluster" "yc_cluster" {
  name                    = var.cluster_name

  master {
    zonal {
      zone      = var.zone
      subnet_id = var.subnet_id
    }
    version               = var.k8s_version
    public_ip             = true
  }

  network_id              = var.network_id

  service_account_id      = var.service_account_id
  node_service_account_id = var.service_account_id

  release_channel         = "RAPID"
  network_policy_provider = "CALICO"

  timeouts {
    create = "30m"
    update = "30m"
  }

  depends_on = [yandex_iam_service_account.otus_sa]
}

# Создание групп узлов для рабочих нагрузок
resource "yandex_kubernetes_node_group" "workload_node_group" {
  cluster_id  = yandex_kubernetes_cluster.yc_cluster.id

  name        = "${var.cluster_name}-workload"
  version     = var.k8s_version
  count       = var.workload_nodes_count

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = [var.subnet_id]
    }

    resources {
      memory = var.node_memory_size
      cores  = var.node_cpu_count
    }

    boot_disk {
      type = "network-ssd"
      size = var.node_disk_size
    }

    scheduling_policy {
      preemptible = false
    }

    # container_runtime {
    #   type = "containerd"
    # }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }
  depends_on = [yandex_kubernetes_cluster.yc_cluster]
  # Создание метки для узлов этой группы для управления раскаткой нагрузки
  
  node_labels = {
    worknode = "true"
  }

}
# Генерация случайного суффикса для имени S3-бакета
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
# Создание S3-бакета для хранения 
resource "yandex_storage_bucket" "volume1" {
  access_key = yandex_iam_service_account_static_access_key.s3.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3.secret_key
  bucket        = "volume-${random_id.bucket_suffix.hex}"
  force_destroy = true
  depends_on = [yandex_iam_service_account.otus_sa]
}
# Создание статического ключа доступа для S3
resource "yandex_iam_service_account_static_access_key" "s3" {
  service_account_id = yandex_iam_service_account.otus_sa.id
  description        = "S3 access key"
  depends_on = [yandex_iam_service_account.otus_sa]
}
# создания секретов
resource "kubernetes_secret" "csi_s3_secret" {
  metadata {
    name      = "csi-s3-secret"
    namespace = "kube-system"
  }

  data = {
    accessKeyID     = yandex_iam_service_account_static_access_key.s3.access_key
    secretAccessKey = yandex_iam_service_account_static_access_key.s3.secret_key
    endpoint        = "https://storage.yandexcloud.net"
    
  }
  depends_on = [yandex_iam_service_account_static_access_key.s3]
}
# Выходные переменные для отображения cluster_endpoint и cluster_ca_certificate кластера Kubernetes.
output "cluster_endpoint" {
  value = yandex_kubernetes_cluster.yc_cluster.master.0.external_v4_endpoint
}

output "cluster_ca_certificate" {
  value = yandex_kubernetes_cluster.yc_cluster.master.0.cluster_ca_certificate
}