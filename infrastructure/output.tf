output "vm-acs-ip" {
  value = azurerm_linux_virtual_machine.nice-rhel-vm-acs.private_ip_address
}