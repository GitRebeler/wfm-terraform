output "vm-app1-ip" {
  value = azurerm_linux_virtual_machine.nice-rhel-vm-app1.private_ip_address
}
output "vm-app2-ip" {
  value = azurerm_linux_virtual_machine.nice-rhel-vm-app2.private_ip_address
}
output "vm-web1-ip" {
  value = azurerm_linux_virtual_machine.nice-rhel-vm-web1.private_ip_address
}
output "vm-web2-ip" {
  value = azurerm_linux_virtual_machine.nice-rhel-vm-web2.private_ip_address
}
output "vm-acs-ip" {
  value = azurerm_linux_virtual_machine.nice-rhel-vm-acs.private_ip_address
}
output "vm-db-fqdn" {
  value = azurerm_postgresql_flexible_server.nice-pgsql.fqdn
}
output "vm-lb-ip" {
  value = azurerm_lb.nice-loadbalancer.private_ip_address
}