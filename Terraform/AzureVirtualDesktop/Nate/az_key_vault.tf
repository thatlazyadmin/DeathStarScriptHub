resource "azurerm_key_vault_secret" "avd_vm_username" {
  count = var.vm_count

  name         = "${var.resource_naming_prefix}-${format("%02d", count.index + 1)}-vm-username"
  value        = azurerm_windows_virtual_machine.avd[count.index].admin_username
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "avd_vm_password" {
  count = var.vm_count

  name         = "${var.resource_naming_prefix}-${format("%02d", count.index + 1)}-vm-password"
  value        = azurerm_windows_virtual_machine.avd[count.index].admin_password
  key_vault_id = var.key_vault_id
}