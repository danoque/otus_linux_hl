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
1.1) В данном случае с помощью yandexcloud CLI были созданы необходимые данные для доступа к облаку и помещены в terraform.tfvars вместе с остальными секретами. В terraform.tfvars.example хранится пример таких данных.
```
service_account_key_file = "/path/to//key.json"
```

2) Используем terraform.tfvars и variables.tf при заполнении чувствительных данных
```
provider "yandex" {
  zone = var.zone
  service_account_key_file = var.service_account_key_file
  folder_id = var.folder_id
}
```
3) С помощью outputs.tf попросим Terraform вывести в консоль необходимые нам данные о созданной машине:
```
output "external_ip_address_app" {
  value = yandex_compute_instance.terraform-first.network_interface.0.nat_ip_address
}
```
4) Terraform  plan - планируем изменения, делаем финальную проверку создаваемого ресурса
5) Terraform apply - создаём ресурс и видим успешный вывод, файл hosts.ini для ansible playbook будет создан автоматически.

```Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_kubemaster = "51.250.94.131"
external_ip_address_kubeworker = [
  "158.160.58.155",
]
internal_ip_address_kubemaster = "192.168.79.100"
internal_ip_address_kubeworker = [
  "192.168.79.11",
]
```
6) Запустим плейбук для деплоя k8s 
```
ansible-playbook deploy_k8s.yaml
```
7) Были выполнены все tasks
```
PLAY RECAP *******************************************************************************************************************************************************************************
kubemaster                 : ok=22   changed=16   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
kubeworker1                : ok=15   changed=12   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
8) Зайдём на сервер по ssh и выведем информацию о нодах k8s
```
daniil@DaniilMosyagin:~/OTUS/otus_linux_hl/k8s-yc$ ssh ubuntu@51.250.94.131
Welcome to Ubuntu 20.04.5 LTS (GNU/Linux 5.4.0-137-generic x86_64)
Last login: Tue Mar  7 09:02:28 2023
ubuntu@kubemaster:~$ kubectl get nodes
NAME           STATUS   ROLES           AGE     VERSION
kubemaster     Ready    control-plane   3m42s   v1.26.2
kubeworker-1   Ready    <none>          3m10s   v1.26.2
```
