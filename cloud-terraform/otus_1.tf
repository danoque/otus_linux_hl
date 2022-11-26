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
resource "yandex_compute_instance" "terraform-first" {
  name = "terraform-first"
  
  resources {
    cores = 2
    memory = 2
}
  boot_disk {
    initialize_params {
      image_id = var.image_id   
    }

  }
  metadata = {
   ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }
}
