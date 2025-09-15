# This file pertains to all components needed to create the AVD environment aside from the VM and Storage Account components
resource "azurerm_virtual_desktop_workspace" "avd_ws" {
  name                = "${var.resource_naming_prefix}-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name

  friendly_name = var.avd_friendly_name
  description   = "Workspace configured for ${var.resource_naming_prefix} AVD Deployment"

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }
}

resource "azurerm_virtual_desktop_host_pool" "avd_hp" {
  location            = var.location
  resource_group_name = var.resource_group_name

  name               = "${var.resource_naming_prefix}-hostpool"
  type               = var.avd_host_type
  load_balancer_type = var.avd_lb_type

  personal_desktop_assignment_type = var.personal_desktop_assignment_type
  maximum_sessions_allowed         = var.avd_max_sessions
  start_vm_on_connect              = true
  custom_rdp_properties            = var.entra_id_enabled == true ? var.host_pool_rdp_properties_entra_joined : var.host_pool_rdp_properties

  friendly_name = "${var.avd_friendly_name} Host Pool"
  description   = "Host Pool configured for ${var.resource_naming_prefix} AVD Deployment"

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"],
    custom_rdp_properties, load_balancer_type, maximum_sessions_allowed]
  }
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_hp_ri" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd_hp.id
  expiration_date = time_rotating.avd_tdo.rotation_rfc3339
}

resource "azurerm_virtual_desktop_application_group" "avd_dag" {
  name                = "${var.resource_naming_prefix}-dag"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                         = "Desktop"
  host_pool_id                 = azurerm_virtual_desktop_host_pool.avd_hp.id
  friendly_name                = "${var.avd_friendly_name} Host Application Group"
  default_desktop_display_name = var.session_desktop_friendly_name != null ? var.session_desktop_friendly_name : "${var.avd_friendly_name} Desktop"
  description                  = "Desktop application group for ${var.resource_naming_prefix} AVD Deployment"

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_waga" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd_ws.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_dag.id
}