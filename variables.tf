variable "location" {
  type = string
  default = "eastus"
}

variable "password" {
  type = string
  default = "E@gL3Ey3$!"
}

variable "service" {
  type = string
  default = "wfm"
}

variable "environment" {
  type = string
  default = "poc"
}

variable "environment-short" {
  type = string
  default = "p"
}

variable "vm-base-os-type-acronym" {
  type = string
  default = "l"
  #l for linux
}

variable "region" {
  type = string
  default = "use"
}

variable "instance" {
  type = string
  default = "03"
}

variable "client" {
  type = string
  default = "cloudlab"
}

variable "clientcode" {
  type = string
  default = "clb"
}

variable "vm-size-app" {
  type = string
  default = "Standard_D4ads_v5"
}

variable "vm-size-web" {
  type = string
  default = "Standard_D2s_v3"
}

variable "vm-username-app1" {
  type = string
  default = "wfmtlapp1clbadmin"
}

variable "vm-username-app2" {
  type = string
  default = "wfmtlapp2clbadmin"
}

variable "vm-username-web1" {
  type = string
  default = "wfmtlweb1clbadmin"
}

variable "vm-username-web2" {
  type = string
  default = "wfmtlweb2clbadmin"
}

variable "vm-username-db" {
  type = string
  default = "wfmtldbclbadmin"
}

variable "puppet-manifest" {
  type = string
  default = "wfm.pp"
}

# Objects are populated in common.auto.tfvars
variable "image-config" {
  type = object({
    offer     = string
    publisher = string
    sku       = string
    version   = string
  })
}

variable "subnet-ids" {
  type = object({
    file-storage = string
    application = string
    frontend = string
    data = string
  })
}

variable "private-dns-zone-ids" {
  type = object({
    file-storage = string
    database = string
  })
}

variable "private-connection-resource-ids" {
  type = object({
    file-storage = string
  })
}