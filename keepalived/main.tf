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


resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name = "subnet1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.56.0/24"]
}

resource "yandex_compute_instance" "host1" {
  count = 1
  name = "host1"
  hostname = "host1"

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
  subnet_id = yandex_vpc_subnet.subnet-1.id
  nat = true
  ip_address = "192.168.56.50"
}  

metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
}
}

resource "yandex_compute_instance" "host2" {
  count = 1
  name = "host2"
  hostname = "host2"

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
  subnet_id = yandex_vpc_subnet.subnet-1.id
  nat = true
  ip_address = "192.168.56.51"
}  

metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
}
}

resource "yandex_compute_instance" "host3" {
  count = 1
  name = "host3"
  hostname = "host3"

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
  subnet_id = yandex_vpc_subnet.subnet-1.id
  nat = true
  ip_address = "192.168.56.200"
}  

metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
}
}