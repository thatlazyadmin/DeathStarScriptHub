#VM Extension to join machine to Domain
resource "azurerm_virtual_machine_extension" "onprem_domain_join" {
  count                      = local.avd_onprem_domain_join
  name                       = "avd-onprem-domain-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.ad_domain_name}",
      "OUPath": "${var.ad_ou_path}",
      "User": "${var.ad_domain_name}\\${var.ad_domain_join_user}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.ad_domain_join_user_pw}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings, tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }

}

#VM Extension to entra-id join machines
resource "azurerm_virtual_machine_extension" "entra_id_join" {
  count                = local.avd_entra_id_join
  name                 = "avd-entra-id-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd[count.index].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "2.2"

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }
}

#VM Extension to join machine to Host Pool with Registration Token
resource "azurerm_virtual_machine_extension" "hostpool_join" {
  count                      = var.vm_count
  name                       = "avd-hostpool-join-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.avd_hp.name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_desktop_host_pool.avd_hp,
  ]

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }
}