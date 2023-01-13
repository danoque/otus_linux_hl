// Outputs

output "external_ip_address_server-pcs-servers" {
  value = [yandex_compute_instance.server-pcs-servers[*].hostname, yandex_compute_instance.server-pcs-servers[*].network_interface.0.nat_ip_address]
}

output "internal_ip_address_server-pcs-servers" {
  value = [yandex_compute_instance.server-pcs-servers[*].hostname, yandex_compute_instance.server-pcs-servers[*].network_interface.0.ip_address]
}

output "external_ip_address_server-iscsi-servers" {
  value = [yandex_compute_instance.server-iscsi-servers[*].hostname, yandex_compute_instance.server-iscsi-servers[*].network_interface.0.nat_ip_address]
}

output "internal_ip_address_server-iscsi-servers" {
  value = [yandex_compute_instance.server-iscsi-servers[*].hostname, yandex_compute_instance.server-iscsi-servers[*].network_interface.0.ip_address]
}

// Outputs