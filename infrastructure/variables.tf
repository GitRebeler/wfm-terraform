variable "loc" {
  type    = string
  default = "eastus"
}

variable "svc" {
  type    = string
  default = "wfm"
}

variable "env" {
  type    = string
  default = "poc"
}

variable "env-short" {
  type    = string
  default = "p"
}

variable "rgn" {
  type    = string
  default = "use"
}

variable "inst" {
  type    = string
  default = "03"
}

variable "clientcode" {
  type    = string
  default = "clb"
}

variable "client" {
  type    = string
  default = "cloudlab"
}

variable "vm-os" {
  type    = string
  default = "l"
  #l for linux
}

variable "vm-size-app" {
  type    = string
  default = "Standard_D4ads_v5"
}

variable "vm-size-web" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "db-size" {
  type    = string
  default = "Standard_D16ds_v5"
}

variable "vm-username-app1" {
  type    = string
  default = "wfmtlapp1clbadmin"
}

variable "vm-username-app2" {
  type    = string
  default = "wfmtlapp2clbadmin"
}

variable "vm-username-web1" {
  type    = string
  default = "wfmtlweb1clbadmin"
}

variable "vm-username-web2" {
  type    = string
  default = "wfmtlweb2clbadmin"
}

variable "vm-username-db" {
  type    = string
  default = "wfmtldbclbadmin"
}

variable "password" {
  type    = string
  default = "E@gL3Ey3$!"
}

variable "puppet-manifest" {
  type    = string
  default = "wfm.pp"
}

variable "deployment-number" {
  type    = string
  default = "01"
}

# Objects are populated in ../env-vars/<env>.tfvars
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
    application  = string
    frontend     = string
    data         = string
  })
}

variable "private-dns-zone-ids" {
  type = object({
    file-storage = string
    database     = string
  })
}