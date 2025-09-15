# A number of default permissions are required for AVD access / support
resource "azurerm_role_assignment" "desktop_virtual_rbac_user_dag" {
  for_each             = var.rbac_desktop_user_group_ids
  scope                = azurerm_virtual_desktop_application_group.avd_dag.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = each.key
}

# now to add at the resource group level permissions for roles required for support by relevant groups
resource "azurerm_role_assignment" "desktop_virtual_rbac_avd_host_pool_reader" {
  for_each             = var.rbac_avd_support_group_ids
  scope                = var.resource_group_id
  role_definition_name = "Desktop Virtualization Host Pool Reader"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "desktop_virtual_rbac_avd_on_off_cont" {
  for_each             = var.rbac_avd_support_group_ids
  scope                = var.resource_group_id
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "desktop_virtual_rbac_avd_reader" {
  for_each             = var.rbac_avd_support_group_ids
  scope                = var.resource_group_id
  role_definition_name = "Desktop Virtualization Reader"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "desktop_virtual_rbac_avd_user_sess_op" {
  for_each             = var.rbac_avd_support_group_ids
  scope                = var.resource_group_id
  role_definition_name = "Desktop Virtualization User Session Operator"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "desktop_virtual_rbac_avd_entra_joined_user_login" {
  for_each             = local.user_login_rbac
  scope                = var.resource_group_id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "desktop_virtual_rbac_avd_entra_joined_admin_login" {
  for_each             = local.admin_login_rbac
  scope                = var.resource_group_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = each.key
}

# General Contributor role to be applied for now, anything further will be discussed / amended
resource "azurerm_role_assignment" "rg_contributor" {
  for_each             = var.rbac_rg_contributor_group_ids
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = each.key
}