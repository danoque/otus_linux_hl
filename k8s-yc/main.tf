terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = var.zone
  service_account_key_file = var.service_account_key_file
  folder_id = var.folder_id
}

resource "yandex_compute_instance" "kubeworker" {
  count = 1
  name = "kubeworker${count.index+1}"
  hostname = "kubeworker-${count.index+1}"

  resources {
    cores = 2
    memory = 4
  }

boot_disk {
  initialize_params {
    image_id = "fd8snjpoq85qqv0mk9gi"
    size = 20
  }
}
#lifecycle {
#    ignore_changes = [attached_disk]
#  }

network_interface {
  subnet_id = yandex_vpc_subnet.cluster-net.id
  nat = true
  ip_address = "192.168.79.1${count.index+1}"
}  

metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

}

resource "yandex_compute_instance" "kubemaster" {
  name = "kubemaster"
  hostname = "kubemaster"

  resources {
    cores = 2
    memory = 4
  }

boot_disk {
  initialize_params {
    image_id = "fd8snjpoq85qqv0mk9gi"
    size = 20
  }
}

network_interface {
  subnet_id = yandex_vpc_subnet.cluster-net.id
  ip_address = "192.168.79.100"
  nat = true
}  

metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

#connection {
#user = "ubuntu"
#private_key = file("~/.ssh/id_rsa")
#host = yandex_compute_instance.vm-gfs2[*].network_interface.0.nat_ip_address
#}
#provisioner "remote-exec" {
#inline = [
#"sudo apt update && sudo apt upgrade -y",
#]
#}

}

resource "local_file" "inventory" {
 filename = "hosts.ini"
 content = <<EOF
[control_plane]
${yandex_compute_instance.kubemaster.name} ansible_host=${yandex_compute_instance.kubemaster.network_interface.0.nat_ip_address} ansible_user=ubuntu
[workers]
${yandex_compute_instance.kubeworker.0.name} ansible_host=${yandex_compute_instance.kubeworker.0.network_interface.0.nat_ip_address} ansible_user=ubuntu
EOF
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "cluster-net" {
  name = "cluster-net"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.79.0/24"]
}

output "internal_ip_address_kubeworker" {
  description = "Internal IP address"
  value = yandex_compute_instance.kubeworker[*].network_interface.0.ip_address
}

output "external_ip_address_kubeworker" {
description = "External IP address"
value = yandex_compute_instance.kubeworker[*].network_interface.0.nat_ip_address
}
output "internal_ip_address_kubemaster" {
  description = "Internal IP address"
  value = yandex_compute_instance.kubemaster.network_interface.0.ip_address
}

output "external_ip_address_kubemaster" {
description = "External IP address"
value = yandex_compute_instance.kubemaster.network_interface.0.nat_ip_address
}


#output "link_to_web_server" {
#description = "URL of Web Server"
#value = "http://${yandex_compute_instance.vm-gfs2[*].network_interface.0.nat_ip_address}"
#}
