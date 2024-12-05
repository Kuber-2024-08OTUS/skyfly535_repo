output "master_ip_addr" {
  value = yandex_compute_instance.master.0.network_interface.0.nat_ip_address
}

output "worker_ip_addr" {
  value = yandex_compute_instance.worker.*.network_interface.0.nat_ip_address
}