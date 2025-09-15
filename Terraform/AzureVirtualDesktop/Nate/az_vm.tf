resource "azurerm_virtual_machine" "sessionhost" {
  count                 = var.vm_count
  name                  = "${var.resource_naming_prefix}-avd-sh-${count.index + 1}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  vm_size               = var.vm_size

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name                     = "${var.resource_naming_prefix}-avd-osdisk-${count.index + 1}"
    caching                  = "ReadWrite"
    create_option            = "FromImage"
    managed_disk_type        = var.vm_os_disk_storage_acount_type
    disk_size_gb             = tonumber(var.vm_os_disk_size)
    write_accelerator_enabled = var.vm_os_disk_write_accelerator_enabled
  }

  storage_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  os_profile {
    computer_name  = "${var.resource_naming_prefix}-avd-sh-${count.index + 1}"
    admin_username = var.vm_admin_user
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent         = var.provision_vm_agent
    enable_automatic_upgrades  = var.vm_enable_automatic_updates
  }

  license_type               = var.vm_license_type

  tags = merge(
    var.vm_tags,
    {
      Environment    = "AVD"
      DeploymentType = "EntraID-Joined"
    }
  )
}

resource "azurerm_virtual_machine_extension" "avd_agent_install" {
  count                = var.vm_count
  name                 = "avdAgentInstall-${count.index + 1}"
  virtual_machine_id   = element(azurerm_virtual_machine.sessionhost.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -Uri https://aka.ms/avd-agent -OutFile C:\\avd-agent.msi; Start-Process msiexec.exe -ArgumentList '/i C:\\avd-agent.msi /quiet /norestart' -Wait\""
  })
}

resource "azurerm_virtual_machine_extension" "entra_id_join" {
  count                = var.vm_count
  name                 = "avd-entra-id-join"
  virtual_machine_id   = azurerm_virtual_machine.sessionhost[count.index].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "2.2"
}