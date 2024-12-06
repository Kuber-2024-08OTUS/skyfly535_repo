variable "service_account_key_file" {
  description = "Path to service account key file"
}

variable "cloud_id" {
  description = "Cloud"
}

variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "folder_id" {
  description = "Folder"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "image_id" {
  description = "image_id"
}

variable "service_account_id" {
  description = "Service account"
}

variable "network_id" {
  description = "Network"
}

variable "subnet_id" {
  description = "Subnet"
}

variable "node_cpu_count_master" {
  description = "Node CPU count master"
}

variable "node_memory_size_master" {
  description = "Node memory size master"
}

variable "node_disk_size_master" {
  description = "Node disk size master"
}

variable "node_cpu_count_worker" {
  description = "Node CPU count worker"
}

variable "node_memory_size_worker" {
  description = "Node memory size worker"
}

variable "node_disk_size_worker" {
  description = "Node disk size worker"
}

variable "workload_nodes_count" {
  description = "Nodes count"
}

variable "cp_nodes_count" {
  description = "Nodes count"
}