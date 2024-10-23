locals {
  formatted_name        = "${var.svc}-${var.env}-${var.rgn}-${var.inst}"
  formatted_name_for_rg = "${var.svc}-${var.env}-${var.rgn}-${var.inst}-${var.clientcode}-${var.inst}"
  formatted_vm_prefix   = "${var.svc}-${var.env-short}${var.vm-os}"
  vm_name_prefix        = "${var.svc}-tl-"
  vm_web_names          = [for i in range(1, (var.deployment-number + 1)) : format("%s%s%02d%s%s", local.vm_name_prefix, "web", i, "-", var.clientcode)]
  vm_app_names          = [for i in range(1, (var.deployment-number + 1)) : format("%s%s%02d%s%s", local.vm_name_prefix, "app", i, "-", var.clientcode)]
  vm_web1_name          = "${local.formatted_vm_prefix}-web1-${var.clientcode}"
  vm_web2_name          = "${local.formatted_vm_prefix}-web2-${var.clientcode}"
  vm_app1_name          = "${local.formatted_vm_prefix}-app1-${var.clientcode}"
  vm_app2_name          = "${local.formatted_vm_prefix}-app2-${var.clientcode}"
  vm_acs_name           = "${local.formatted_vm_prefix}-db-${var.clientcode}"
  vm_db_name            = "${local.formatted_vm_prefix}-acs-${var.clientcode}"
  data_inputs = {
    service = var.svc
    vm_web1_name = local.vm_web1_name
    vm_web2_name = local.vm_web2_name
    vm_app1_name = local.vm_app1_name
    vm_app2_name = local.vm_app2_name
    vm_acs_name = local.vm_acs_name
    vm_db_name = local.vm_db_name
    clientcode = var.clientcode
  }
  instance_user_data = {
    write_files = [
      {
        encoding = "b64"
        content  = templatefile("ud.tftpl", local.data_inputs)
        path     = "/tmp/infra.json"
      }
    ]
  }
}

resource "azurerm_resource_group" "rg" {
  location = var.loc
  name     = "${local.formatted_name_for_rg}-rg"
}

# NSGs
resource "azurerm_network_security_group" "nice-nsg-app1" {
  location            = var.loc
  name                = "${local.formatted_vm_prefix}-app1-${var.clientcode}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_security_group" "nice-nsg-app2" {
  location            = var.loc
  name                = "${local.formatted_vm_prefix}-app2-${var.clientcode}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_security_group" "nice-nsg-web1" {
  location            = var.loc
  name                = "${local.formatted_vm_prefix}-web1-${var.clientcode}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_security_group" "nice-nsg-web2" {
  location            = var.loc
  name                = "${local.formatted_vm_prefix}-web2-${var.clientcode}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_security_group" "nice-nsg-db" {
  location            = var.loc
  name                = "${local.formatted_vm_prefix}-db-${var.clientcode}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_security_group" "nice-nsg-ascwa" {
  count = var.create-ascwa == true ? 1 : tonumber("0")
  location            = var.loc
  name                = "${local.formatted_vm_prefix}-ascwa-${var.clientcode}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# NICs
resource "azurerm_network_interface" "nice-nic-app1" {
  location                       = var.loc
  name                           = "${local.formatted_vm_prefix}-app1-${var.clientcode}_z1"
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet-ids.application
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_interface_security_group_association" "nice-nic-nsg-asc-app1" {
  network_interface_id      = azurerm_network_interface.nice-nic-app1.id
  network_security_group_id = azurerm_network_security_group.nice-nsg-app1.id
  depends_on = [
    azurerm_network_interface.nice-nic-app1,
    azurerm_network_security_group.nice-nsg-app1,
  ]
}
resource "azurerm_network_interface" "nice-nic-app2" {
  location                       = var.loc
  name                           = "${local.formatted_vm_prefix}-app2-${var.clientcode}_z2"
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet-ids.application
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_interface_security_group_association" "nice-nic-nsg-asc-app2" {
  network_interface_id      = azurerm_network_interface.nice-nic-app2.id
  network_security_group_id = azurerm_network_security_group.nice-nsg-app2.id
  depends_on = [
    azurerm_network_interface.nice-nic-app2,
    azurerm_network_security_group.nice-nsg-app2,
  ]
}
resource "azurerm_network_interface" "nice-nic-web1" {
  location                       = var.loc
  name                           = "${local.formatted_vm_prefix}-web1-${var.clientcode}_z1"
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet-ids.frontend
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_interface_backend_address_pool_association" "nice-nic-bea-asc-web1" {
  backend_address_pool_id = azurerm_lb_backend_address_pool.nice-be-addr-pool.id
  ip_configuration_name   = "ipconfig1"
  network_interface_id    = azurerm_network_interface.nice-nic-web1.id
  depends_on = [
    azurerm_lb_backend_address_pool.nice-be-addr-pool,
    azurerm_network_interface.nice-nic-web1,
  ]
}
resource "azurerm_network_interface" "nice-nic-web2" {
  location                       = var.loc
  name                           = "${local.formatted_vm_prefix}-web2-${var.clientcode}_z2"
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet-ids.frontend
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_interface_backend_address_pool_association" "nice-nic-bea-asc-web2" {
  backend_address_pool_id = azurerm_lb_backend_address_pool.nice-be-addr-pool.id
  ip_configuration_name   = "ipconfig1"
  network_interface_id    = azurerm_network_interface.nice-nic-web2.id
  depends_on = [
    azurerm_lb_backend_address_pool.nice-be-addr-pool,
    azurerm_network_interface.nice-nic-web2,
  ]
}
resource "azurerm_network_interface_security_group_association" "nice-nic-nsg-asc-web2" {
  network_interface_id      = azurerm_network_interface.nice-nic-web2.id
  network_security_group_id = azurerm_network_security_group.nice-nsg-web2.id
  depends_on = [
    azurerm_network_interface.nice-nic-web2,
    azurerm_network_security_group.nice-nsg-web2,
  ]
}
resource "azurerm_network_interface" "nice-nic-ascwa" {
  count = var.create-ascwa == true ? 1 : tonumber("0")
  location                       = var.loc
  name                           = "${local.formatted_vm_prefix}-ascwa-${var.clientcode}_z1"
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet-ids.application
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_network_interface_security_group_association" "nice-nic-nsg-asc-ascwa" {
  count = var.create-ascwa == true ? 1 : tonumber("0")
  network_interface_id      = azurerm_network_interface.nice-nic-ascwa[count.index].id
  network_security_group_id = azurerm_network_security_group.nice-nsg-ascwa[count.index].id
  depends_on = [
    azurerm_network_interface.nice-nic-ascwa,
    azurerm_network_security_group.nice-nsg-ascwa,
  ]
}

resource "azurerm_private_endpoint" "nice-pvt-endpt" {
  custom_network_interface_name = "${var.svc}-${var.env}-${var.rgn}-${var.inst}-${var.clientcode}-${var.inst}-sa-${var.inst}-pe-${var.inst}-nic"
  location                      = var.loc
  name                          = "${var.svc}-${var.env}-${var.rgn}-${var.inst}-${var.clientcode}-${var.inst}-sa-${var.inst}-pe-${var.inst}"
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = var.subnet-ids.file-storage
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private-dns-zone-ids.file-storage]
  }
  private_service_connection {
    is_manual_connection           = false
    name                           = "${var.svc}-${var.env}-${var.rgn}-${var.inst}-${var.clientcode}-${var.inst}-sa-${var.inst}-pe-${var.inst}"
    private_connection_resource_id = azurerm_storage_account.nice-storage-acct.id
    subresource_names              = ["file"]
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

resource "azurerm_storage_account" "nice-storage-acct" {
  account_replication_type         = "RAGRS"
  account_tier                     = "Standard"
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false
  location                         = var.loc
  name                             = "${var.svc}${var.env}${var.rgn}${var.inst}${var.clientcode}${var.inst}sa${var.inst}"
  public_network_access_enabled    = false
  resource_group_name              = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "nice-rhel-vm-app1" {
  admin_password                  = var.password
  admin_username                  = var.vm-username-app1
  disable_password_authentication = false
  location                        = var.loc
  name                            = "${local.formatted_vm_prefix}-app1-${var.clientcode}"
  network_interface_ids           = [azurerm_network_interface.nice-nic-app1.id]
  resource_group_name             = azurerm_resource_group.rg.name
  secure_boot_enabled             = true
  size                            = var.vm-size-app
  tags = {
    nice_client          = var.client
    nice_clientcode      = var.clientcode
    nice_datacenter      = var.loc
    nice_dr              = var.nice-dr
    nice_environment     = var.nice-environment
    nice_instanceid      = var.nice-instanceid
    nice_product         = var.svc
    nice_puppet_manifest = var.puppet-manifest
    nice_serverrole      = "app"
    nice_state           = "live"
  }
  vtpm_enabled = true
  zone         = "1"
  additional_capabilities {
  }
  boot_diagnostics {
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = var.image-config.offer
    publisher = var.image-config.publisher
    sku       = var.image-config.sku
    version   = var.image-config.version
  }
  depends_on = [
    azurerm_network_interface.nice-nic-app1,
  ]
}
resource "azurerm_linux_virtual_machine" "nice-rhel-vm-app2" {
  admin_password                  = var.password
  admin_username                  = var.vm-username-app2
  disable_password_authentication = false
  location                        = var.loc
  name                            = "${local.formatted_vm_prefix}-app2-${var.clientcode}"
  network_interface_ids           = [azurerm_network_interface.nice-nic-app2.id]
  resource_group_name             = azurerm_resource_group.rg.name
  secure_boot_enabled             = true
  size                            = var.vm-size-app
  tags = {
    nice_client          = var.client
    nice_clientcode      = var.clientcode
    nice_datacenter      = var.loc
    nice_dr              = var.nice-dr
    nice_environment     = var.nice-environment
    nice_instanceid      = var.nice-instanceid
    nice_product         = var.svc
    nice_puppet_manifest = var.puppet-manifest
    nice_serverrole      = "app"
    nice_state           = "live"
  }
  vtpm_enabled = true
  zone         = "2"
  additional_capabilities {
  }
  boot_diagnostics {
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = var.image-config.offer
    publisher = var.image-config.publisher
    sku       = var.image-config.sku
    version   = var.image-config.version
  }
  depends_on = [
    azurerm_network_interface.nice-nic-app2,
  ]
}
resource "azurerm_linux_virtual_machine" "nice-rhel-vm-web1" {
  admin_password                  = var.password
  admin_username                  = var.vm-username-web1
  disable_password_authentication = false
  location                        = var.loc
  name                            = "${local.formatted_vm_prefix}-web1-${var.clientcode}"
  network_interface_ids           = [azurerm_network_interface.nice-nic-web1.id]
  resource_group_name             = azurerm_resource_group.rg.name
  secure_boot_enabled             = true
  size                            = var.vm-size-web
  tags = {
    nice_client          = var.client
    nice_clientcode      = var.clientcode
    nice_datacenter      = var.loc
    nice_dr              = var.nice-dr
    nice_environment     = var.nice-environment
    nice_instanceid      = var.nice-instanceid
    nice_product         = var.svc
    nice_puppet_manifest = var.puppet-manifest
    nice_serverrole      = "web"
    nice_state           = "live"
  }
  vtpm_enabled = true
  zone         = "1"
  additional_capabilities {
  }
  boot_diagnostics {
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = var.image-config.offer
    publisher = var.image-config.publisher
    sku       = var.image-config.sku
    version   = var.image-config.version
  }
  depends_on = [
    azurerm_network_interface.nice-nic-web1,
  ]
}
resource "azurerm_linux_virtual_machine" "nice-rhel-vm-web2" {
  admin_password                  = var.password
  admin_username                  = var.vm-username-web2
  disable_password_authentication = false
  location                        = var.loc
  name                            = "${local.formatted_vm_prefix}-web2-${var.clientcode}"
  network_interface_ids           = [azurerm_network_interface.nice-nic-web2.id]
  resource_group_name             = azurerm_resource_group.rg.name
  secure_boot_enabled             = true
  size                            = var.vm-size-web
  tags = {
    nice_client          = var.client
    nice_clientcode      = var.clientcode
    nice_datacenter      = var.loc
    nice_dr              = var.nice-dr
    nice_environment     = var.nice-environment
    nice_instanceid      = var.nice-instanceid
    nice_product         = var.svc
    nice_puppet_manifest = var.puppet-manifest
    nice_serverrole      = "web"
    nice_state           = "live"
  }
  vtpm_enabled = true
  zone         = "2"
  additional_capabilities {
  }
  boot_diagnostics {
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = var.image-config.offer
    publisher = var.image-config.publisher
    sku       = var.image-config.sku
    version   = var.image-config.version
  }
  depends_on = [
    azurerm_network_interface.nice-nic-web2,
  ]
}
resource "azurerm_linux_virtual_machine" "nice-rhel-vm-acs" {
  count = var.create-ascwa == true ? 1 : tonumber("0")
  admin_password                  = var.password
  admin_username                  = var.vm-username-acswa
  disable_password_authentication = false
  location                        = var.loc
  name                            = "${local.formatted_vm_prefix}-acs-${var.clientcode}"
  network_interface_ids           = [azurerm_network_interface.nice-nic-ascwa[count.index].id]
  resource_group_name             = azurerm_resource_group.rg.name
  secure_boot_enabled             = true
  size                            = var.vm-size-web
  tags = {
    nice_client          = var.client
    nice_clientcode      = var.clientcode
    nice_datacenter      = var.loc
    nice_dr              = var.nice-dr
    nice_environment     = var.nice-environment
    nice_instanceid      = var.nice-instanceid
    nice_product         = var.svc
    nice_puppet_manifest = var.puppet-manifest
    nice_serverrole      = "acswa"
    nice_state           = "live"
  }
  vtpm_enabled = true
  zone         = "2"
  additional_capabilities {
  }
  boot_diagnostics {
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  # provisioner "file" {
  #   content     = base64encode(templatefile("userdataInfra.tftpl", local.data_inputs))
  #   destination = "/etc/nca/infra.json"
    
  #   connection {
  #     type="ssh"
  #     user = var.vm-username-acswa
  #     password = var.password
  #     host = azurerm_linux_virtual_machine.nice-rhel-vm-acs[count.index].private_ip_address
  #   }
  # }

  source_image_reference {
    offer     = var.image-config.offer
    publisher = var.image-config.publisher
    sku       = var.image-config.sku
    version   = var.image-config.version
  }
  # user_data = base64encode(templatefile("userdata.tftpl", local.data_inputs))
  user_data = base64encode("${yamlencode(local.instance_user_data)}")

  depends_on = [
    azurerm_network_interface.nice-nic-web2,
  ]
}

# VM Managed Disks
resource "azurerm_managed_disk" "nice-managed-disk-web1" {
  create_option = "Empty"
  location      = var.loc
  # name                 = "wfm-tl-web1-clb_DataDisk_0"
  name                 = "${local.formatted_vm_prefix}-web1-${var.clientcode}_DataDisk_0"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  disk_size_gb         = 64
  zone                 = "1"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_managed_disk" "nice-managed-disk-web2" {
  create_option = "Empty"
  location      = var.loc
  # name                 = "wfm-tl-web2-clb_DataDisk_0"
  name                 = "${local.formatted_vm_prefix}-web2-${var.clientcode}_DataDisk_0"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  disk_size_gb         = 64
  zone                 = "2"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# Attaching the VM Managed Disks
resource "azurerm_virtual_machine_data_disk_attachment" "nice-vm-datadisk-atch-web1" {
  caching            = "ReadOnly"
  lun                = 0
  managed_disk_id    = azurerm_managed_disk.nice-managed-disk-web1.id
  virtual_machine_id = azurerm_linux_virtual_machine.nice-rhel-vm-web1.id
  depends_on = [
    azurerm_linux_virtual_machine.nice-rhel-vm-web1,
    azurerm_managed_disk.nice-managed-disk-web1,
  ]
}
resource "azurerm_virtual_machine_data_disk_attachment" "nice-vm-datadisk-atch-web2" {
  caching            = "ReadOnly"
  lun                = 0
  managed_disk_id    = azurerm_managed_disk.nice-managed-disk-web2.id
  virtual_machine_id = azurerm_linux_virtual_machine.nice-rhel-vm-web2.id
  depends_on = [
    azurerm_linux_virtual_machine.nice-rhel-vm-web2,
    azurerm_managed_disk.nice-managed-disk-web2,
  ]
}

# Azure Load Balancer
resource "azurerm_lb" "nice-loadbalancer" {
  location            = var.loc
  name                = "${local.formatted_name_for_rg}-lb-${var.inst}"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "${local.formatted_name_for_rg}-ip-${var.inst}"
    zones     = ["1", "2", "3"]
    subnet_id = var.subnet-ids.frontend
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_lb_backend_address_pool" "nice-be-addr-pool" {
  loadbalancer_id = azurerm_lb.nice-loadbalancer.id
  name            = "${local.formatted_name_for_rg}-bp-${var.inst}"
  depends_on = [
    azurerm_lb.nice-loadbalancer,
  ]
}
resource "azurerm_lb_rule" "nice-lb-rule-tcp80" {
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nice-be-addr-pool.id]
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "${local.formatted_name_for_rg}-ip-${var.inst}"
  frontend_port                  = 80
  loadbalancer_id                = azurerm_lb.nice-loadbalancer.id
  name                           = "load-balancing-rule-tcp80"
  protocol                       = "Tcp"
  depends_on = [
    azurerm_lb_backend_address_pool.nice-be-addr-pool,
  ]
}
resource "azurerm_lb_rule" "nice-lb-rule-tcp88" {
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nice-be-addr-pool.id]
  backend_port                   = 88
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "${local.formatted_name_for_rg}-ip-${var.inst}"
  frontend_port                  = 88
  loadbalancer_id                = azurerm_lb.nice-loadbalancer.id
  name                           = "load-balancing-rule-tcp88"
  protocol                       = "Tcp"
  depends_on = [
    azurerm_lb_backend_address_pool.nice-be-addr-pool,
  ]
}
resource "azurerm_lb_probe" "nice-lb-probe-tcp80" {
  interval_in_seconds = 5
  loadbalancer_id     = azurerm_lb.nice-loadbalancer.id
  name                = "health-probe-tcp80"
  number_of_probes    = 1
  port                = 80
  depends_on = [
    azurerm_lb.nice-loadbalancer,
  ]
}
resource "azurerm_lb_probe" "nice-lb-probe-tcp88" {
  interval_in_seconds = 5
  loadbalancer_id     = azurerm_lb.nice-loadbalancer.id
  name                = "health-probe-tcp88"
  number_of_probes    = 1
  port                = 88
  depends_on = [
    azurerm_lb.nice-loadbalancer,
  ]
}

# Azure Datebae for PostgresSQL flexible server
resource "azurerm_postgresql_flexible_server" "nice-pgsql" {
  delegated_subnet_id = var.subnet-ids.data
  private_dns_zone_id = var.private-dns-zone-ids.database
  location            = var.loc
  # name                = "wfm-tl-dbs-clb"
  name                   = "${local.formatted_vm_prefix}-dbs-${var.clientcode}"
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = var.vm-username-db
  administrator_password = var.password
  sku_name               = var.db-size
  storage_mb             = 1048576 # should be 700 GB but the closes option rounded up to 1 TB
  version                = 16
  public_network_access_enabled = false
  tags = {
    nice_client          = var.client
    nice_clientcode      = var.clientcode
    nice_datacenter      = var.loc
    nice_dr              = var.nice-dr
    nice_environment     = var.nice-environment
    nice_instanceid      = var.nice-instanceid
    nice_product         = var.svc
    nice_puppet_manifest = var.puppet-manifest
    nice_serverrole      = "dbpostgres"
    nice_state           = "live"
  }
  zone = "3"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_postgresql_flexible_server_configuration" "pgsql-sec-transport" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.nice-pgsql.id
  value     = "OFF"
  depends_on = [
    azurerm_postgresql_flexible_server.nice-pgsql,
  ]
}
# resource "azurerm_postgresql_flexible_server_configuration" "res-10" {
#   name      = "DateStyle"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "ISO, MDY"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-11" {
#   name      = "IntervalStyle"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "postgres"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-12" {
#   name      = "TimeZone"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "UTC"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-13" {
#   name      = "allow_in_place_tablespaces"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-14" {
#   name      = "allow_system_table_mods"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-15" {
#   name      = "application_name"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-16" {
#   name      = "archive_cleanup_command"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-17" {
#   name      = "archive_command"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "BlobLogUpload.sh %f %p"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-18" {
#   name      = "archive_library"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-19" {
#   name      = "archive_mode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "always"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-20" {
#   name      = "archive_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "300"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-21" {
#   name      = "array_nulls"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-22" {
#   name      = "authentication_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "30"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-23" {
#   name      = "auto_explain.log_analyze"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-24" {
#   name      = "auto_explain.log_buffers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-25" {
#   name      = "auto_explain.log_format"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "text"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-26" {
#   name      = "auto_explain.log_level"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "log"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-27" {
#   name      = "auto_explain.log_min_duration"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-28" {
#   name      = "auto_explain.log_nested_statements"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-29" {
#   name      = "auto_explain.log_settings"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-30" {
#   name      = "auto_explain.log_timing"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-31" {
#   name      = "auto_explain.log_triggers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-32" {
#   name      = "auto_explain.log_verbose"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-33" {
#   name      = "auto_explain.log_wal"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-34" {
#   name      = "auto_explain.sample_rate"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1.0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-35" {
#   name      = "autovacuum"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-36" {
#   name      = "autovacuum_analyze_scale_factor"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-37" {
#   name      = "autovacuum_analyze_threshold"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "50"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-38" {
#   name      = "autovacuum_freeze_max_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "200000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-39" {
#   name      = "autovacuum_max_workers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "3"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-40" {
#   name      = "autovacuum_multixact_freeze_max_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "400000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-41" {
#   name      = "autovacuum_naptime"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "60"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-42" {
#   name      = "autovacuum_vacuum_cost_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-43" {
#   name      = "autovacuum_vacuum_cost_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-44" {
#   name      = "autovacuum_vacuum_insert_scale_factor"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-45" {
#   name      = "autovacuum_vacuum_insert_threshold"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-46" {
#   name      = "autovacuum_vacuum_scale_factor"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-47" {
#   name      = "autovacuum_vacuum_threshold"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "50"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-48" {
#   name      = "autovacuum_work_mem"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-49" {
#   name      = "azure.accepted_password_auth_method"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "md5,scram-sha-256"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-50" {
#   name      = "azure.enable_temp_tablespaces_on_local_ssd"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-51" {
#   name      = "azure.extensions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-52" {
#   name      = "azure.single_to_flex_migration"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-53" {
#   name      = "azure_storage.allow_network_access"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-54" {
#   name      = "azure_storage.blob_block_size_mb"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "256"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-55" {
#   name      = "azure_storage.public_account_access"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-56" {
#   name      = "backend_flush_after"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "256"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-57" {
#   name      = "backslash_quote"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "safe_encoding"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-58" {
#   name      = "backtrace_functions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-59" {
#   name      = "bgwriter_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "20"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-60" {
#   name      = "bgwriter_flush_after"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "64"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-61" {
#   name      = "bgwriter_lru_maxpages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "100"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-62" {
#   name      = "bgwriter_lru_multiplier"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-63" {
#   name      = "block_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "8192"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-64" {
#   name      = "bonjour"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-65" {
#   name      = "bonjour_name"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-66" {
#   name      = "bytea_output"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "hex"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-67" {
#   name      = "check_function_bodies"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-68" {
#   name      = "checkpoint_completion_target"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.9"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-69" {
#   name      = "checkpoint_flush_after"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "32"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-70" {
#   name      = "checkpoint_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "600"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-71" {
#   name      = "checkpoint_warning"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "30"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-72" {
#   name      = "client_connection_check_interval"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-73" {
#   name      = "client_encoding"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "UTF8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-74" {
#   name      = "client_min_messages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "notice"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-75" {
#   name      = "cluster_name"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-76" {
#   name      = "commit_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-77" {
#   name      = "commit_siblings"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-78" {
#   name      = "compute_query_id"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "auto"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-79" {
#   name      = "config_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/pg/data/postgresql.conf"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-80" {
#   name      = "connection_throttle.bucket_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-81" {
#   name      = "connection_throttle.enable"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-82" {
#   name      = "connection_throttle.factor_bias"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-83" {
#   name      = "connection_throttle.hash_entries_max"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "500"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-84" {
#   name      = "connection_throttle.reset_time"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "120"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-85" {
#   name      = "connection_throttle.restore_factor"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-86" {
#   name      = "connection_throttle.update_time"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "20"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-87" {
#   name      = "constraint_exclusion"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "partition"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-88" {
#   name      = "cpu_index_tuple_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.005"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-89" {
#   name      = "cpu_operator_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.0025"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-90" {
#   name      = "cpu_tuple_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.01"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-91" {
#   name      = "cron.database_name"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "postgres"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-92" {
#   name      = "cron.log_run"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-93" {
#   name      = "cron.log_statement"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-94" {
#   name      = "cron.max_running_jobs"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "32"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-95" {
#   name      = "cursor_tuple_fraction"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-96" {
#   name      = "data_checksums"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-97" {
#   name      = "data_directory"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/pg/data"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-98" {
#   name      = "data_directory_mode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0700"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-99" {
#   name      = "data_sync_retry"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-100" {
#   name      = "db_user_namespace"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-101" {
#   name      = "deadlock_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-102" {
#   name      = "debug_assertions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-103" {
#   name      = "debug_discard_caches"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-104" {
#   name      = "debug_parallel_query"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-105" {
#   name      = "debug_pretty_print"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-106" {
#   name      = "debug_print_parse"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-107" {
#   name      = "debug_print_plan"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-108" {
#   name      = "debug_print_rewritten"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-109" {
#   name      = "default_statistics_target"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "100"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-110" {
#   name      = "default_table_access_method"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "heap"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-111" {
#   name      = "default_tablespace"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-112" {
#   name      = "default_text_search_config"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "pg_catalog.english"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-113" {
#   name      = "default_toast_compression"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "pglz"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-114" {
#   name      = "default_transaction_deferrable"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-115" {
#   name      = "default_transaction_isolation"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "read committed"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-116" {
#   name      = "default_transaction_read_only"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-117" {
#   name      = "dynamic_library_path"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "$libdir"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-118" {
#   name      = "dynamic_shared_memory_type"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "posix"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-119" {
#   name      = "effective_cache_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "786432"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-120" {
#   name      = "effective_io_concurrency"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-121" {
#   name      = "enable_async_append"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-122" {
#   name      = "enable_bitmapscan"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-123" {
#   name      = "enable_gathermerge"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-124" {
#   name      = "enable_hashagg"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-125" {
#   name      = "enable_hashjoin"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-126" {
#   name      = "enable_incremental_sort"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-127" {
#   name      = "enable_indexonlyscan"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-128" {
#   name      = "enable_indexscan"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-129" {
#   name      = "enable_material"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-130" {
#   name      = "enable_memoize"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-131" {
#   name      = "enable_mergejoin"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-132" {
#   name      = "enable_nestloop"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-133" {
#   name      = "enable_parallel_append"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-134" {
#   name      = "enable_parallel_hash"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-135" {
#   name      = "enable_partition_pruning"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-136" {
#   name      = "enable_partitionwise_aggregate"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-137" {
#   name      = "enable_partitionwise_join"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-138" {
#   name      = "enable_seqscan"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-139" {
#   name      = "enable_sort"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-140" {
#   name      = "enable_tidscan"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-141" {
#   name      = "escape_string_warning"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-142" {
#   name      = "event_source"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "PostgreSQL"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-143" {
#   name      = "exit_on_error"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-144" {
#   name      = "external_pid_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-145" {
#   name      = "extra_float_digits"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-146" {
#   name      = "from_collapse_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-147" {
#   name      = "fsync"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-148" {
#   name      = "full_page_writes"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-149" {
#   name      = "geqo"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-150" {
#   name      = "geqo_effort"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-151" {
#   name      = "geqo_generations"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-152" {
#   name      = "geqo_pool_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-153" {
#   name      = "geqo_seed"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-154" {
#   name      = "geqo_selection_bias"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-155" {
#   name      = "geqo_threshold"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "12"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-156" {
#   name      = "gin_fuzzy_search_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-157" {
#   name      = "gin_pending_list_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "4096"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-158" {
#   name      = "hash_mem_multiplier"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-159" {
#   name      = "hba_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/pg/data/pg_hba.conf"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-160" {
#   name      = "hot_standby"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-161" {
#   name      = "hot_standby_feedback"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-162" {
#   name      = "huge_page_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-163" {
#   name      = "huge_pages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "try"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-164" {
#   name      = "ident_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/pg/data/pg_ident.conf"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-165" {
#   name      = "idle_in_transaction_session_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-166" {
#   name      = "idle_session_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-167" {
#   name      = "ignore_checksum_failure"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-168" {
#   name      = "ignore_invalid_pages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-169" {
#   name      = "ignore_system_indexes"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-170" {
#   name      = "in_hot_standby"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-171" {
#   name      = "integer_datetimes"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-172" {
#   name      = "intelligent_tuning"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-173" {
#   name      = "intelligent_tuning.metric_targets"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-174" {
#   name      = "jit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-175" {
#   name      = "jit_above_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "100000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-176" {
#   name      = "jit_debugging_support"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-177" {
#   name      = "jit_dump_bitcode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-178" {
#   name      = "jit_expressions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-179" {
#   name      = "jit_inline_above_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "500000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-180" {
#   name      = "jit_optimize_above_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "500000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-181" {
#   name      = "jit_profiling_support"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-182" {
#   name      = "jit_provider"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "llvmjit"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-183" {
#   name      = "jit_tuple_deforming"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-184" {
#   name      = "join_collapse_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-185" {
#   name      = "krb_caseins_users"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-186" {
#   name      = "krb_server_keyfile"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-187" {
#   name      = "lc_messages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "en_US.utf8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-188" {
#   name      = "lc_monetary"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "en_US.utf-8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-189" {
#   name      = "lc_numeric"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "en_US.utf-8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-190" {
#   name      = "lc_time"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "en_US.utf8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-191" {
#   name      = "listen_addresses"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "*"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-192" {
#   name      = "lo_compat_privileges"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-193" {
#   name      = "local_preload_libraries"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-194" {
#   name      = "lock_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-195" {
#   name      = "log_autovacuum_min_duration"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-196" {
#   name      = "log_checkpoints"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-197" {
#   name      = "log_connections"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-198" {
#   name      = "log_destination"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "stderr"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-199" {
#   name      = "log_directory"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "log"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-200" {
#   name      = "log_disconnections"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-201" {
#   name      = "log_duration"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-202" {
#   name      = "log_error_verbosity"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "default"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-203" {
#   name      = "log_executor_stats"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-204" {
#   name      = "log_file_mode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0600"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-205" {
#   name      = "log_filename"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "postgresql-%Y-%m-%d_%H%M%S.log"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-206" {
#   name      = "log_hostname"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-207" {
#   name      = "log_line_prefix"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "%t-%c-"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-208" {
#   name      = "log_lock_waits"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-209" {
#   name      = "log_min_duration_sample"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-210" {
#   name      = "log_min_duration_statement"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-211" {
#   name      = "log_min_error_statement"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "error"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-212" {
#   name      = "log_min_messages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "warning"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-213" {
#   name      = "log_parameter_max_length"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-214" {
#   name      = "log_parameter_max_length_on_error"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-215" {
#   name      = "log_parser_stats"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-216" {
#   name      = "log_planner_stats"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-217" {
#   name      = "log_recovery_conflict_waits"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-218" {
#   name      = "log_replication_commands"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-219" {
#   name      = "log_rotation_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "60"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-220" {
#   name      = "log_rotation_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "102400"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-221" {
#   name      = "log_startup_progress_interval"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-222" {
#   name      = "log_statement"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-223" {
#   name      = "log_statement_sample_rate"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-224" {
#   name      = "log_statement_stats"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-225" {
#   name      = "log_temp_files"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-226" {
#   name      = "log_timezone"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "UTC"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-227" {
#   name      = "log_transaction_sample_rate"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-228" {
#   name      = "log_truncate_on_rotation"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-229" {
#   name      = "logfiles.download_enable"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-230" {
#   name      = "logfiles.retention_days"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "3"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-231" {
#   name      = "logging_collector"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-232" {
#   name      = "logical_decoding_work_mem"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "65536"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-233" {
#   name      = "maintenance_io_concurrency"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-234" {
#   name      = "maintenance_work_mem"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "216064"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-235" {
#   name      = "max_connections"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "859"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-236" {
#   name      = "max_files_per_process"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-237" {
#   name      = "max_function_args"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "100"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-238" {
#   name      = "max_identifier_length"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "63"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-239" {
#   name      = "max_index_keys"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "32"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-240" {
#   name      = "max_locks_per_transaction"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "64"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-241" {
#   name      = "max_logical_replication_workers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "4"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-242" {
#   name      = "max_parallel_maintenance_workers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-243" {
#   name      = "max_parallel_workers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-244" {
#   name      = "max_parallel_workers_per_gather"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-245" {
#   name      = "max_pred_locks_per_page"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-246" {
#   name      = "max_pred_locks_per_relation"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-247" {
#   name      = "max_pred_locks_per_transaction"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "64"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-248" {
#   name      = "max_prepared_transactions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-249" {
#   name      = "max_replication_slots"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-250" {
#   name      = "max_slot_wal_keep_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-251" {
#   name      = "max_stack_depth"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2048"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-252" {
#   name      = "max_standby_archive_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "30000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-253" {
#   name      = "max_standby_streaming_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "30000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-254" {
#   name      = "max_sync_workers_per_subscription"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-255" {
#   name      = "max_wal_senders"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-256" {
#   name      = "max_wal_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "12288"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-257" {
#   name      = "max_worker_processes"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-258" {
#   name      = "metrics.autovacuum_diagnostics"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-259" {
#   name      = "metrics.collector_database_activity"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-260" {
#   name      = "metrics.pgbouncer_diagnostics"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-261" {
#   name      = "min_dynamic_shared_memory"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-262" {
#   name      = "min_parallel_index_scan_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "64"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-263" {
#   name      = "min_parallel_table_scan_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1024"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-264" {
#   name      = "min_wal_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "80"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-265" {
#   name      = "parallel_leader_participation"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-266" {
#   name      = "parallel_setup_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-267" {
#   name      = "parallel_tuple_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0.1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-268" {
#   name      = "password_encryption"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "scram-sha-256"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-269" {
#   name      = "pg_partman_bgw.analyze"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-270" {
#   name      = "pg_partman_bgw.dbname"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-271" {
#   name      = "pg_partman_bgw.interval"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "3600"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-272" {
#   name      = "pg_partman_bgw.jobmon"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-273" {
#   name      = "pg_partman_bgw.role"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-274" {
#   name      = "pg_qs.interval_length_minutes"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "15"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-275" {
#   name      = "pg_qs.is_enabled_fs"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-276" {
#   name      = "pg_qs.max_plan_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "7500"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-277" {
#   name      = "pg_qs.max_query_text_length"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "6000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-278" {
#   name      = "pg_qs.query_capture_mode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-279" {
#   name      = "pg_qs.retention_period_in_days"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "7"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-280" {
#   name      = "pg_qs.store_query_plans"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-281" {
#   name      = "pg_qs.track_utility"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-282" {
#   name      = "pg_stat_statements.max"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-283" {
#   name      = "pg_stat_statements.save"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-284" {
#   name      = "pg_stat_statements.track"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-285" {
#   name      = "pg_stat_statements.track_utility"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-286" {
#   name      = "pgaudit.log"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-287" {
#   name      = "pgaudit.log_catalog"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-288" {
#   name      = "pgaudit.log_client"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-289" {
#   name      = "pgaudit.log_level"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "log"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-290" {
#   name      = "pgaudit.log_parameter"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-291" {
#   name      = "pgaudit.log_relation"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-292" {
#   name      = "pgaudit.log_statement_once"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-293" {
#   name      = "pgaudit.role"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-294" {
#   name      = "pgbouncer.enabled"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "false"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-295" {
#   name      = "pglogical.batch_inserts"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-296" {
#   name      = "pglogical.conflict_log_level"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "log"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-297" {
#   name      = "pglogical.conflict_resolution"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "apply_remote"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-298" {
#   name      = "pglogical.use_spi"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-299" {
#   name      = "pgms_stats.is_enabled_fs"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-300" {
#   name      = "pgms_wait_sampling.history_period"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "100"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-301" {
#   name      = "pgms_wait_sampling.is_enabled_fs"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-302" {
#   name      = "pgms_wait_sampling.query_capture_mode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-303" {
#   name      = "plan_cache_mode"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "auto"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-304" {
#   name      = "port"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5432"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-305" {
#   name      = "post_auth_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-306" {
#   name      = "postgis.gdal_enabled_drivers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "DISABLE_ALL"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-307" {
#   name      = "pre_auth_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-308" {
#   name      = "primary_conninfo"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-309" {
#   name      = "primary_slot_name"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-310" {
#   name      = "quote_all_identifiers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-311" {
#   name      = "random_page_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-312" {
#   name      = "recovery_end_command"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-313" {
#   name      = "recovery_init_sync_method"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "fsync"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-314" {
#   name      = "recovery_min_apply_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-315" {
#   name      = "recovery_prefetch"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "try"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-316" {
#   name      = "recovery_target"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-317" {
#   name      = "recovery_target_action"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "pause"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-318" {
#   name      = "recovery_target_inclusive"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-319" {
#   name      = "recovery_target_lsn"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-320" {
#   name      = "recovery_target_name"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-321" {
#   name      = "recovery_target_time"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-322" {
#   name      = "recovery_target_timeline"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "latest"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-323" {
#   name      = "recovery_target_xid"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-324" {
#   name      = "recursive_worktable_factor"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-325" {
#   name      = "remove_temp_files_after_crash"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-327" {
#   name      = "reserved_connections"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-328" {
#   name      = "restart_after_crash"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-329" {
#   name      = "restore_command"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-330" {
#   name      = "row_security"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-331" {
#   name      = "search_path"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "\"$user\", public"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-332" {
#   name      = "segment_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "131072"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-333" {
#   name      = "seq_page_cost"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-334" {
#   name      = "server_encoding"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "UTF8"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-335" {
#   name      = "server_version"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "16.3"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-336" {
#   name      = "server_version_num"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "160003"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-337" {
#   name      = "session_preload_libraries"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-338" {
#   name      = "session_replication_role"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "origin"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-339" {
#   name      = "shared_buffers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "262144"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-340" {
#   name      = "shared_memory_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2168"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-341" {
#   name      = "shared_memory_size_in_huge_pages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1084"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-342" {
#   name      = "shared_memory_type"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "mmap"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-343" {
#   name      = "shared_preload_libraries"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "pg_cron,pg_stat_statements"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-344" {
#   name      = "ssl"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-345" {
#   name      = "ssl_ca_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/certs/ca.pem"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-346" {
#   name      = "ssl_cert_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/certs/cert.pem"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-347" {
#   name      = "ssl_ciphers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-348" {
#   name      = "ssl_crl_dir"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-349" {
#   name      = "ssl_crl_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-350" {
#   name      = "ssl_dh_params_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-351" {
#   name      = "ssl_ecdh_curve"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "prime256v1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-352" {
#   name      = "ssl_key_file"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/datadrive/certs/key.pem"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-353" {
#   name      = "ssl_library"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "OpenSSL"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-354" {
#   name      = "ssl_max_protocol_version"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-355" {
#   name      = "ssl_min_protocol_version"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "TLSv1.2"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-356" {
#   name      = "ssl_passphrase_command"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-357" {
#   name      = "ssl_passphrase_command_supports_reload"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-358" {
#   name      = "ssl_prefer_server_ciphers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-359" {
#   name      = "standard_conforming_strings"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-360" {
#   name      = "statement_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-361" {
#   name      = "stats_fetch_consistency"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "cache"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-362" {
#   name      = "superuser_reserved_connections"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-363" {
#   name      = "synchronize_seqscans"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-364" {
#   name      = "synchronous_commit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-365" {
#   name      = "synchronous_standby_names"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-366" {
#   name      = "syslog_facility"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "local0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-367" {
#   name      = "syslog_ident"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "postgres"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-368" {
#   name      = "syslog_sequence_numbers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-369" {
#   name      = "syslog_split_messages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-370" {
#   name      = "tcp_keepalives_count"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "9"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-371" {
#   name      = "tcp_keepalives_idle"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "120"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-372" {
#   name      = "tcp_keepalives_interval"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "30"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-373" {
#   name      = "tcp_user_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-374" {
#   name      = "temp_buffers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1024"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-375" {
#   name      = "temp_file_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "-1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-376" {
#   name      = "temp_tablespaces"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "temptblspace"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-377" {
#   name      = "timezone_abbreviations"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "Default"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-378" {
#   name      = "trace_notify"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-379" {
#   name      = "trace_recovery_messages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "log"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-380" {
#   name      = "trace_sort"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-381" {
#   name      = "track_activities"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-382" {
#   name      = "track_activity_query_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1024"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-383" {
#   name      = "track_commit_timestamp"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-384" {
#   name      = "track_counts"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-385" {
#   name      = "track_functions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "none"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-386" {
#   name      = "track_io_timing"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-387" {
#   name      = "track_wal_io_timing"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-388" {
#   name      = "transaction_deferrable"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-389" {
#   name      = "transaction_isolation"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "read committed"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-390" {
#   name      = "transaction_read_only"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-391" {
#   name      = "transform_null_equals"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-392" {
#   name      = "unix_socket_directories"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "/tmp"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-393" {
#   name      = "unix_socket_group"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-394" {
#   name      = "unix_socket_permissions"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0777"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-395" {
#   name      = "update_process_title"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-396" {
#   name      = "vacuum_cost_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "0"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-397" {
#   name      = "vacuum_cost_limit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "200"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-398" {
#   name      = "vacuum_cost_page_dirty"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "20"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-399" {
#   name      = "vacuum_cost_page_hit"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-400" {
#   name      = "vacuum_cost_page_miss"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-401" {
#   name      = "vacuum_failsafe_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1600000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-402" {
#   name      = "vacuum_freeze_min_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "50000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-403" {
#   name      = "vacuum_freeze_table_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "150000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-404" {
#   name      = "vacuum_multixact_failsafe_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "1600000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-405" {
#   name      = "vacuum_multixact_freeze_min_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-406" {
#   name      = "vacuum_multixact_freeze_table_age"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "150000000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-407" {
#   name      = "wal_block_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "8192"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-408" {
#   name      = "wal_buffers"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2048"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-409" {
#   name      = "wal_compression"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-410" {
#   name      = "wal_consistency_checking"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = ""
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-411" {
#   name      = "wal_decode_buffer_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "524288"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-412" {
#   name      = "wal_init_zero"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-413" {
#   name      = "wal_keep_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "400"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-414" {
#   name      = "wal_level"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "replica"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-415" {
#   name      = "wal_log_hints"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-416" {
#   name      = "wal_receiver_create_temp_slot"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-417" {
#   name      = "wal_receiver_status_interval"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "10"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-418" {
#   name      = "wal_receiver_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "60000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-419" {
#   name      = "wal_recycle"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "on"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-420" {
#   name      = "wal_retrieve_retry_interval"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "5000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-421" {
#   name      = "wal_segment_size"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "16777216"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-422" {
#   name      = "wal_sender_timeout"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "60000"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-423" {
#   name      = "wal_skip_threshold"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "2048"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-424" {
#   name      = "wal_sync_method"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "fdatasync"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-425" {
#   name      = "wal_writer_delay"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "200"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-426" {
#   name      = "wal_writer_flush_after"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "128"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-427" {
#   name      = "work_mem"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "4096"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-428" {
#   name      = "xmlbinary"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "base64"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-429" {
#   name      = "xmloption"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "content"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_configuration" "res-430" {
#   name      = "zero_damaged_pages"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   value     = "off"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_database" "res-431" {
#   name      = "WFM_CLB_CUSTOMER01"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_database" "res-432" {
#   name      = "WFM_CLB_DIAGTENANT"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_database" "res-433" {
#   name      = "WFM_CLB_SYSTEM"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_database" "res-434" {
#   name      = "azure_maintenance"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_database" "res-435" {
#   name      = "azure_sys"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }
# resource "azurerm_postgresql_flexible_server_database" "res-436" {
#   name      = "postgres"
#   server_id = "/subscriptions/194a41a1-5592-4d4f-a8db-9eba93938aa2/resourceGroups/wfm-dev-use-01-clb-01-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/wfm-tl-dbs-clb"
#   depends_on = [
#     azurerm_postgresql_flexible_server.nice-pgsql,
#   ]
# }