terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
  service_account_key_file = "/home/daniil/OTUS/key.json"
  folder_id = "b1go7pq0c5r5n54tpjj3"
}
resource "yandex_compute_instance" "terraform-first" {
  name = "terraform-first"
  
  resources {
    cores = 2
    memory = 2
}
  boot_disk {
    initialize_params {
      image_id = "fd89jk9j9vifp28uprop"   
    }

  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
  network_interface {
    subnet_id = "e9bbn4t2n1m995m76cbi"
    nat = true
  }
}
