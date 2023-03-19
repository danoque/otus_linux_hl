variable "pve_ip_address" {
  type = string
  description = "IP address of PVE web interface"
}

variable "pm_user" {
  type = string
  description = "User with privelege, by default use service provider terraform-prov@pve"
}

variable "pm_password" {
  type = string
  description = "Password of pm_user"
}

variable "proxmox_host" {
  type = string
  description = "Hostname PVE node"
}

variable "template" {
  type = string
  description = "Template for controllers nodes"
}

variable "storage" {
  type = string
}

variable "ssh_keys" {
  default = "COPY YOU id_rsa.pub here"
}
