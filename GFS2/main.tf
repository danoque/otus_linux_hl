// Provider configuration
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

//provider "yandex" {
//  token     = var.access["token"]
//  cloud_id  = var.access["cloud_id"]
//  folder_id = var.access["folder_id"]
//  zone      = var.access["zone"]
//}
// Provider configuration

// Create VM
resource "yandex_compute_instance" "server-pcs-servers" {

  name                      = "server-pcs-${count.index + 1}"
  count                     = var.data
  platform_id               = "standard-v1"
  hostname                  = "server-pcs-${count.index + 1}"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    core_fraction = 20
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd85vbr6kin3r8ro2e95" //Ubuntu
      size     = 10
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.pcs-servers-subnet-01.id
    nat       = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.pcs-servers-subnet-02.id
    nat        = false
    ip_address = "10.180.3.20${count.index + 1}"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-02.id
    nat        = false
    ip_address = "10.180.1.20${count.index + 1}"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-03.id
    nat        = false
    ip_address = "10.180.2.20${count.index + 1}"
  }

  metadata = {
   user-data = "${file("./meta.yml")}" 
   ssh-keys = "user:${file(var.public_key_path)}"
  }  

  depends_on = [
    yandex_compute_instance.server-iscsi-servers
  ]
}

resource "yandex_compute_instance" "server-iscsi-servers" {

  name                      = "server-iscsi-1"
  count                     = 1
  platform_id               = "standard-v1"
  hostname                  = "server-iscsi-1"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    core_fraction = 20
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd85vbr6kin3r8ro2e95" //Ubuntu
      size     = 10
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.iscsi-servers-subnet-01.id
    nat       = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-02.id
    nat        = false
    ip_address = "10.180.1.204"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-03.id
    nat        = false
    ip_address = "10.180.2.204"
  }

  secondary_disk {
    disk_id = yandex_compute_disk.server-iscsi-secondary-data-disk.id
  }

  metadata = {
   user-data = "${file("./meta.yml")}" 
   ssh-keys = "user:${file(var.public_key_path)}"
  }  
}
// Create VM

// Create Networks
resource "yandex_vpc_network" "ru-central1-a-servers-network-01" {
  name = "pcs-servers-network-01"
}
// Create Networks

// Create Subnets
resource "yandex_vpc_subnet" "pcs-servers-subnet-01" {
  name           = "pcs-servers-subnet-01"
  zone           = var.zone
  network_id     = yandex_vpc_network.ru-central1-a-servers-network-01.id
  v4_cidr_blocks = ["10.160.0.0/24"]
}

resource "yandex_vpc_subnet" "pcs-servers-subnet-02" {
  name           = "pcs-servers-subnet-02"
  zone           = var.zone
  network_id     = yandex_vpc_network.ru-central1-a-servers-network-01.id
  v4_cidr_blocks = ["10.180.3.0/24"]
}

resource "yandex_vpc_subnet" "iscsi-servers-subnet-01" {
  name           = "iscsi-servers-subnet-01"
  zone           = var.zone
  network_id     = yandex_vpc_network.ru-central1-a-servers-network-01.id
  v4_cidr_blocks = ["10.180.0.0/24"]
}

resource "yandex_vpc_subnet" "iscsi-servers-subnet-02" {
  name           = "iscsi-servers-subnet-02"
  zone           = var.zone
  network_id     = yandex_vpc_network.ru-central1-a-servers-network-01.id
  v4_cidr_blocks = ["10.180.1.0/24"]
}

resource "yandex_vpc_subnet" "iscsi-servers-subnet-03" {
  name           = "iscsi-servers-subnet-03"
  zone           = var.zone
  network_id     = yandex_vpc_network.ru-central1-a-servers-network-01.id
  v4_cidr_blocks = ["10.180.2.0/24"]
}

// Create Subnets

// Create secondary disks

resource "yandex_compute_disk" "server-iscsi-secondary-data-disk" {

  name = "server-iscsi-secondary-data-disk-01"
  type = "network-hdd"
  zone = var.zone
  size = "1"
}

// Create secondary disks

// Check SSH connection and output debug message

resource "null_resource" "ansible-install-pcs-servers" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = format("ansible-playbook -D -i %s, -u ${var.data["account"]} ${path.module}/ansible/accessebility.yml",
      join("\",\"", yandex_compute_instance.server-pcs-servers[*].network_interface.0.nat_ip_address, yandex_compute_instance.server-iscsi-servers[*].network_interface.0.nat_ip_address)
    )
  }
}

// Check SSH connection and output debug message

// Create hosts file for Ansible

resource "local_file" "hosts_ini" {
  filename = "./ansible-provision/hosts.ini"

  content = <<-EOT
[all]
%{for ip in yandex_compute_instance.server-iscsi-servers[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
%{for ip in yandex_compute_instance.server-pcs-servers[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
[iscsi_servers]
%{for ip in yandex_compute_instance.server-iscsi-servers[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
[pcs_servers]
%{for ip in yandex_compute_instance.server-pcs-servers[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
EOT
}

// Create hosts file for Ansible