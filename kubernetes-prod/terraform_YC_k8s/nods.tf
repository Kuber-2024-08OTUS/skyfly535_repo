# описание ноды с Сontrol plane (master)
resource "yandex_compute_instance" "master" {
  count = var.cp_nodes_count
  name  = "k8s-master-${count.index}"
  hostname = "master-${count.index}"
  

  resources {
    cores  = var.node_cpu_count_master
    memory = var.node_memory_size_master
  }

  boot_disk {
    initialize_params {
      type = "network-ssd"
      image_id = var.image_id # ID образа Ubuntu 20.04 LTS
      size = var.node_disk_size_master
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
    user-data = file("${path.module}/userdata.yaml")
  }
}

# описание worker нод
resource "yandex_compute_instance" "worker" {
  count = var.workload_nodes_count
  name  = "k8s-worker-${count.index}"
  hostname = "worker${count.index}"

  resources {
    cores  = var.node_cpu_count_worker
    memory = var.node_memory_size_worker
  }

  boot_disk {
    initialize_params {
      type = "network-ssd"
      image_id = var.image_id # ID образа Ubuntu 20.04 LTS
      size = var.node_disk_size_worker
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
    user-data = file("${path.module}/userdata.yaml")
  }
}
