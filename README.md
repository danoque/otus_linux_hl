# otus_linux_hl
# otus_linux_hl
Работа с Terraform и Proxmox начинается с создания cloud-init образа. Готовый образ с Proxmox для виртуальной машины можно скачать с официального сайта. Выполним эти шаги на уже установленной операционной системе с Proxmox.
```
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```
Установим необходимые пакеты для работы с образом
```
sudo apt update -y && sudo apt install libguestfs-tools -y
```
Самое главное - установить qemu-guest-agent в образ
```
sudo virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
```
Теперь создадим из образа виртуальную машину, а затем создадим для неё необходимые компоненты, диск, сеть, консоль
```
sudo qm create 9000 --name "ubuntu-2004-cloudinit-template" --memory 2048 --cores 1 --net0 virtio,bridge=vmbr0
sudo qm importdisk 9000 focal-server-cloudimg-amd64.img local-zfs
sudo qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9000-disk-0
sudo qm set 9000 --boot c --bootdisk scsi0
sudo qm set 9000 --ide2 local-zfs:cloudinit
sudo qm set 9000 --serial0 socket --vga serial0
sudo qm set 9000 --agent enabled=1
```
Теперь сконвертируем подготовленную виртуальную машину в шаблон, с которым уже будет работать Terraform
```
sudo qm template 9000
```
В wev-интерфесе (или в консоли) созданим пользователя для работы с Terraform и наделим его необходимыми правами
Работа с конфигурацией Terraform:
В main.tf файле инициализируем работу с провайдером Proxmox для terraform 
```
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=1.0.0"
    }
  }
  required_version = ">= 0.13"
}
```
Так же подробно опишем характеристики создаваемых виртуальных машин, память, прцоессор и так далее и добавим файл terraform.tfvars со своими секретными данными
```
provider "proxmox" {
  pm_api_url = "https://192.168.0.13:8006/api2/json"
  pm_user = var.pm_user
  pm_password = var.pm_password
  pm_log_file   = "/proxmox/terraform-plugin-proxmox.log"
 
}

resource "proxmox_vm_qemu" "virtual_machine" {
  count = 2
  name = "TestPVE${count.index + 1}"
  target_node = var.proxmox_host
  clone = var.template
  os_type = "cloud-init"
  agent = 1
  cores = 1
  sockets = "1"
  memory = 1024
  cpu = "host"
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

disk {
    slot = 0
    size = "10G"
    type = "scsi"
    storage = var.storage
    iothread = 1
}
network {
    model = "virtio"
    bridge = "vmbr0"
}

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

# Cloud Init Settings
ipconfig0 = "ip=10.0.155.20${count.index + 1}/24,gw=10.0.155.1"
sshkeys = <<EOF
${var.ssh_keys}
EOF

}

```
Выполним команду terraform init для инициализации провайдера. А затем команду terraform plan для того чтобы удостоверится в создаваемых ресурсах.
Команда terraform apply создаст для нас все запрашиваемые ресурсы


На cloud-init у слабой виртуальной машины с Proxmox ушло почти 12 минут
```
proxmox_vm_qemu.virtual_machine[0]: Still creating... [11m10s elapsed]
proxmox_vm_qemu.virtual_machine[0]: Creation complete after 11m14s [id=proxmox/qemu/101]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
daniil@DaniilMosyagin:~/OTUS/otus_linux_hl/proxmox$ 
```
![Screenshot from 2023-03-19 23-38-53](https://user-images.githubusercontent.com/9090696/226207751-7b305c33-497c-4596-a65a-0bd1fea1c04e.png)
