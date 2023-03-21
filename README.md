# otus_linux_hl
Этот проект развернёт 3 виртуальные машины в Yandex-cloud с помощью Terraform и подготовит эту инфраструктуру для работы keepalived,nginx,базы данных и сайта на базе wordpress.
1) Начинаем писать Terraform файл, вопользуемся Яндекс провайдером
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
3) Terraform  plan - планируем изменения, делаем финальную проверку создаваемого ресурса
4) Terraform apply - создаст две ноды для keepalived и базу данных.
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

5) Далее для установки и настройки keepalived, nginx и БД запустим плейбук
```
ansible-playbook deploy.yaml
```
Адреса виртуальных машин во внутренней сети:
Keepalived: web1 192.168.56.50 и web2 192.168.56.51
База данных: 192.168.56.200
Виртуальный IP, который будет использоваться Keepalived: 192.168.56.10
6) Имитируем отказ nginx на одном из серверов для проверки переключения виртуального адреса keepalived
```
sudo systemctl stop nginx
```
В статусе keepalived на другом сервере увидим следующую картину, из BACKUP STATE keepalived перешёл в MASTER STATE, так как на первом сервере не выполнилась проверка 
```
vrrp_script nginx {
  script "/usr/bin/pgrep nginx"
  interval 1
  weight 3
}
```
```
ubuntu@host2:~$ sudo systemctl status keepalived.service
● keepalived.service - Keepalive Daemon (LVS and VRRP)
     Loaded: loaded (/lib/systemd/system/keepalived.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2023-03-20 21:11:23 UTC; 47s ago
   Main PID: 11585 (keepalived)
      Tasks: 2 (limit: 4646)
     Memory: 2.2M
     CGroup: /system.slice/keepalived.service
             ├─11585 /usr/sbin/keepalived --dont-fork
             └─11591 /usr/sbin/keepalived --dont-fork

Mar 20 21:11:23 host2 Keepalived_vrrp[11591]: Registering Kernel netlink command channel
Mar 20 21:11:23 host2 Keepalived_vrrp[11591]: Opening file '/etc/keepalived/keepalived.conf'.
Mar 20 21:11:23 host2 Keepalived_vrrp[11591]: Registering gratuitous ARP shared channel
Mar 20 21:11:23 host2 Keepalived_vrrp[11591]: (VI_1) Entering BACKUP STATE (init)
Mar 20 21:11:23 host2 Keepalived_vrrp[11591]: VRRP_Script(nginx) succeeded
Mar 20 21:11:23 host2 Keepalived_vrrp[11591]: (VI_1) Changing effective priority from 99 to 102
Mar 20 21:11:53 host2 Keepalived_vrrp[11591]: (VI_1) received lower priority (99) advert from 192.168.56.50 - discarding
Mar 20 21:11:54 host2 Keepalived_vrrp[11591]: (VI_1) received lower priority (99) advert from 192.168.56.50 - discarding
Mar 20 21:11:55 host2 Keepalived_vrrp[11591]: (VI_1) received lower priority (99) advert from 192.168.56.50 - discarding
Mar 20 21:11:55 host2 Keepalived_vrrp[11591]: (VI_1) Entering MASTER STATE

```
Соответственно и виртуальный адрес 192.168.56.10 перешёл на текущую машину:
```
ubuntu@host2:~$ ip a s
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d0:0d:12:43:7b:bd brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.51/24 brd 192.168.56.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 192.168.56.10/24 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d20d:12ff:fe43:7bbd/64 scope link 
       valid_lft forever preferred_lft forever
```
