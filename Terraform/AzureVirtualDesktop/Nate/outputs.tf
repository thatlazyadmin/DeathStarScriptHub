output "avd_vm_ids" {
  description = "The IDs of every AVD VM deployed with this module"
  value       = azurerm_windows_virtual_machine.avd[*].id
}

output "avd_vm_names" {
  description = "The names of every AVD VM deployed with this module"
  value       = azurerm_windows_virtual_machine.avd[*].name
}

output "avd_vm_identities" {
  description = "The managed IDs of every AVD VM deployed with this module (for use with assigning RBAC Roles to other Azure resources as needed)"
  value       = azurerm_windows_virtual_machine.avd[*].identity
}