# for resource information, refer to https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_test_global_vm_shutdown_schedule
# will need to refer to this for setting correct timezones accepted by the code
resource "azurerm_dev_test_global_vm_shutdown_schedule" "avd" {
  count = var.vm_count

  virtual_machine_id = azurerm_windows_virtual_machine.avd[count.index].id
  location           = var.location
  enabled            = var.vm_autoshutdown_enabled

  daily_recurrence_time = var.vm_autoshutdown_time
  timezone              = var.vm_autoshutdown_timezone

  notification_settings {
    enabled = false
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }
}