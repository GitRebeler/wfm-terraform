# Basic configuration variables
loc               = "eastus"
svc               = "wfm"
env               = "prod"
env-short         = "p"
rgn               = "use"
inst              = "03"
clientcode        = "clb"
client            = "cloudlab"
vm-os             = "l"
deployment-number = "01"

# VM configuration variables
vm-size-app       = "Standard_DS1_v2"
vm-size-web       = "Standard_DS1_v2"
vm-size-acs       = "Standard_E16_v5"
db-size           = "Standard_D16ds_v5"
vm-username-app1  = "wfmtlapp1clbadmin"
vm-username-app2  = "wfmtlapp2clbadmin"
vm-username-web1  = "wfmtlweb1clbadmin"
vm-username-web2  = "wfmtlweb2clbadmin"
vm-username-db    = "wfmtldbclbadmin"
vm-username-acswa = "wfmtlacsclbadmin"
password          = "E@gL3Ey3$!"
puppet-manifest   = "wfm.pp"
nice-dr           = "false"
nice-environment  = "production"
nice-instanceid   = "WI104952"
wfm-url           = "nmhc-wfm.nicecloudsvc.com"
nde-url           = "nmhc-nde.nicecloudsvc.com"
create-ascwa      = "true"

image-config = {
  offer     = "RHEL"
  publisher = "RedHat"
  sku       = "89-gen2"
  version   = "latest"
}

# Networking configuration variables
subnet-ids = {
  file-storage = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-rg/providers/Microsoft.Network/virtualNetworks/wfm-dev-use-01-vn-01/subnets/AzureStorageSubnet"
  application  = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-rg/providers/Microsoft.Network/virtualNetworks/wfm-dev-use-01-vn-01/subnets/ApplicationSubnet-01"
  frontend     = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-rg/providers/Microsoft.Network/virtualNetworks/wfm-dev-use-01-vn-01/subnets/FrontendSubnet-01"
  data         = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-rg/providers/Microsoft.Network/virtualNetworks/wfm-dev-use-01-vn-01/subnets/DataSubnet-01"
}

private-dns-zone-ids = {
  file-storage = "/subscriptions/7f4eb505-b5b8-4743-958d-b8c8388c9a1c/resourceGroups/con-dev-use-01-rg/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  database     = "/subscriptions/7f4eb505-b5b8-4743-958d-b8c8388c9a1c/resourceGroups/con-dev-use-01-rg/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
}