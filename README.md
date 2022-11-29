1) Начинаем писать Terraform файл, пользуемся Яндекс провайдером
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
```

3) Используем terraform.tfvars и variables.tf при заполнении чувствительных данных
```
provider "yandex" {
  zone = var.zone
  service_account_key_file = var.service_account_key_file
  folder_id = var.folder_id
}
```
5) С помощью outputs.tf попросим Terraform вывести в консоль необходимые нам данные о созданной машине:
```
output "external_ip_address_app" {
  value = yandex_compute_instance.terraform-first.network_interface.0.nat_ip_address
}
```
7) Terraform  plan - планируем изменения, делаем финальную проверку создаваемого ресурса
8) Terradorm apply - создаём ресурс и видим успешный вывод с нашим outputs
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.67.179"
```
10) Пишем Ansible плейбук для provison nginx, опишем здесь только самое главное - роль nginx, а в hosts укажем IP из вывода Terraform
```
---
  - name: Install nginx
    package:
      name: "nginx"
      state: present

  - name: Check nginx configs
    shell: /usr/sbin/nginx -t

  - name: Reload nginx
    service:
      name: nginx
      state: reloaded

  - name: Make sure nginx is started
    systemd:
      state: started
      enabled: yes
      name: nginx
```
12) Запускаем плейбук
13) После успешного завершения видим, что по нашему IP теперь отвечает стандартное приветственное сообщения nginx.
