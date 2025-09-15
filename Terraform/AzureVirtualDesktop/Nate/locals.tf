locals {
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.avd_hp_ri.token

  avd_onprem_domain_join = var.ad_ou_path != null && var.ad_domain_join_user != null && var.ad_domain_join_user_pw != null && var.entra_id_enabled == false ? var.vm_count : 0
  avd_entra_id_join      = var.entra_id_enabled == true ? var.vm_count : 0

  user_login_rbac  = var.entra_id_enabled == true ? var.rbac_desktop_user_group_ids : []
  admin_login_rbac = var.entra_id_enabled == true ? var.rbac_rg_entra_vm_admin_group_ids : []
}