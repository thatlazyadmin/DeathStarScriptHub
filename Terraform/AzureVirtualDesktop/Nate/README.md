<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_dev_test_global_vm_shutdown_schedule.avd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_test_global_vm_shutdown_schedule) | resource |
| [azurerm_key_vault_secret.avd_vm_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.avd_vm_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_network_interface.avd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_avd_entra_joined_admin_login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_avd_entra_joined_user_login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_avd_host_pool_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_avd_on_off_cont](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_avd_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_avd_user_sess_op](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.desktop_virtual_rbac_user_dag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rg_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_virtual_desktop_application_group.avd_dag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group) | resource |
| [azurerm_virtual_desktop_host_pool.avd_hp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool) | resource |
| [azurerm_virtual_desktop_host_pool_registration_info.avd_hp_ri](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info) | resource |
| [azurerm_virtual_desktop_workspace.avd_ws](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace) | resource |
| [azurerm_virtual_desktop_workspace_application_group_association.avd_waga](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association) | resource |
| [azurerm_virtual_machine_extension.entra_id_join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.hostpool_join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.onprem_domain_join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.avd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_password.vm_random_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.vm_random_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_rotating.avd_tdo](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_domain_join_user"></a> [ad\_domain\_join\_user](#input\_ad\_domain\_join\_user) | Service Account username for joining VMs to the Domain | `string` | `null` | no |
| <a name="input_ad_domain_join_user_pw"></a> [ad\_domain\_join\_user\_pw](#input\_ad\_domain\_join\_user\_pw) | Service Account password for joining VMs to the Domain | `string` | `null` | no |
| <a name="input_ad_domain_name"></a> [ad\_domain\_name](#input\_ad\_domain\_name) | On Prem Active Directory Domain Name for VMs to be joined to | `string` | `"ugl.local"` | no |
| <a name="input_ad_ou_path"></a> [ad\_ou\_path](#input\_ad\_ou\_path) | The On-Prem Active Directory OU where all computer accounts will be created in | `string` | `null` | no |
| <a name="input_avd_friendly_name"></a> [avd\_friendly\_name](#input\_avd\_friendly\_name) | Friendly Name to give the AVD Workspace | `string` | n/a | yes |
| <a name="input_avd_host_type"></a> [avd\_host\_type](#input\_avd\_host\_type) | AVD Host Pool types must be either Personal or Pooled | `string` | `"Pooled"` | no |
| <a name="input_avd_lb_type"></a> [avd\_lb\_type](#input\_avd\_lb\_type) | Type of Load Balancing - 'BreadthFirst' OR 'DepthFirst' OR 'Persistent' | `string` | `"BreadthFirst"` | no |
| <a name="input_avd_max_sessions"></a> [avd\_max\_sessions](#input\_avd\_max\_sessions) | Enter a number value for MAX sessions PER session host | `number` | `8` | no |
| <a name="input_entra_id_enabled"></a> [entra\_id\_enabled](#input\_entra\_id\_enabled) | Will the AVD be Entra ID joined (Checking true will override AD domain join options) | `bool` | `false` | no |
| <a name="input_host_pool_rdp_properties"></a> [host\_pool\_rdp\_properties](#input\_host\_pool\_rdp\_properties) | This variable can be used to set RDP properties for the host pool being created by this module | `string` | `"enablecredsspsupport:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1;"` | no |
| <a name="input_host_pool_rdp_properties_entra_joined"></a> [host\_pool\_rdp\_properties\_entra\_joined](#input\_host\_pool\_rdp\_properties\_entra\_joined) | This variable can be used to set RDP properties for the host pool being created by this module - specifically for Entra-Id joined AVD pools | `string` | `"targetisaadjoined:i:1;enablecredsspsupport:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1;enablerdsaadauth:i:1"` | no |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | ID of Key Vault | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location of resource to manage in Azure; default is uksouth but there may be a requirement for ukwest | `string` | `"uksouth"` | no |
| <a name="input_personal_desktop_assignment_type"></a> [personal\_desktop\_assignment\_type](#input\_personal\_desktop\_assignment\_type) | Required if deploying 'Personal' host pool sessions - options being: Automatic or Direct. Direct is set to Default | `string` | `"Direct"` | no |
| <a name="input_provision_vm_agent"></a> [provision\_vm\_agent](#input\_provision\_vm\_agent) | Provision VM agent (VM Tools) | `bool` | `true` | no |
| <a name="input_rbac_avd_support_group_ids"></a> [rbac\_avd\_support\_group\_ids](#input\_rbac\_avd\_support\_group\_ids) | RBAC Role Assignment for AVD Support Groups via their object IDs | `set(string)` | `[]` | no |
| <a name="input_rbac_desktop_user_group_ids"></a> [rbac\_desktop\_user\_group\_ids](#input\_rbac\_desktop\_user\_group\_ids) | RBAC Role Assignment for Desktop Users Groups via their object IDs | `set(string)` | `[]` | no |
| <a name="input_rbac_rg_contributor_group_ids"></a> [rbac\_rg\_contributor\_group\_ids](#input\_rbac\_rg\_contributor\_group\_ids) | RBAC Role Assignment for Admin Groups via their object IDs (Only for deployments outside of Utilita's Landing Zone due to policy management) | `set(string)` | `[]` | no |
| <a name="input_rbac_rg_entra_vm_admin_group_ids"></a> [rbac\_rg\_entra\_vm\_admin\_group\_ids](#input\_rbac\_rg\_entra\_vm\_admin\_group\_ids) | RBAC Role Assignment for Admin Groups via their object IDs to log onto VMs with Admin permissions when VMs are joined to Entra ID | `set(string)` | `[]` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource Group id where all AVD resources will be created (needed for RBAC) | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group Name where all AVD resources will be created | `string` | n/a | yes |
| <a name="input_resource_naming_prefix"></a> [resource\_naming\_prefix](#input\_resource\_naming\_prefix) | Prefix to attach to all resources being created here | `string` | n/a | yes |
| <a name="input_session_desktop_friendly_name"></a> [session\_desktop\_friendly\_name](#input\_session\_desktop\_friendly\_name) | Friendly Name for the default Session Desktop Link that appears in the Remote Desktop App | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags and values of tags to be used | `map(string)` | `{}` | no |
| <a name="input_vm_admin_user"></a> [vm\_admin\_user](#input\_vm\_admin\_user) | Username of the Admin User for the VMs built | `string` | `"avdroot"` | no |
| <a name="input_vm_allow_extension_operations"></a> [vm\_allow\_extension\_operations](#input\_vm\_allow\_extension\_operations) | Should Extension Operations be allowed on this Virtual Machine? | `bool` | `true` | no |
| <a name="input_vm_autoshutdown_enabled"></a> [vm\_autoshutdown\_enabled](#input\_vm\_autoshutdown\_enabled) | Do we want this VM to auto-shutdown on a daily basis? | `bool` | `true` | no |
| <a name="input_vm_autoshutdown_time"></a> [vm\_autoshutdown\_time](#input\_vm\_autoshutdown\_time) | Time of day we wish to perform the autoshutdown operation e.g. 2200, 1930, 0800 | `string` | `"2000"` | no |
| <a name="input_vm_autoshutdown_timezone"></a> [vm\_autoshutdown\_timezone](#input\_vm\_autoshutdown\_timezone) | What timezone is being referenced for shutting down the VM at the right time | `string` | `"GMT Standard Time"` | no |
| <a name="input_vm_count"></a> [vm\_count](#input\_vm\_count) | Specify the number of VMs to be created for this AVD deployment | `number` | `1` | no |
| <a name="input_vm_enable_automatic_updates"></a> [vm\_enable\_automatic\_updates](#input\_vm\_enable\_automatic\_updates) | Enable automatic patching via Azure (should be false unless otherwise stated, as patch management carried out elsewhere) | `bool` | `false` | no |
| <a name="input_vm_hotpatching_enabled"></a> [vm\_hotpatching\_enabled](#input\_vm\_hotpatching\_enabled) | should hotpatching be enabled for this? | `bool` | `false` | no |
| <a name="input_vm_image_offer"></a> [vm\_image\_offer](#input\_vm\_image\_offer) | Offer Name to use with building the VMs required in the AVD deployment | `string` | `"Windows-11"` | no |
| <a name="input_vm_image_publisher"></a> [vm\_image\_publisher](#input\_vm\_image\_publisher) | Publisher Image Name to use with building the VMs required in the AVD deployment | `string` | `"MicrosoftWindowsDesktop"` | no |
| <a name="input_vm_image_sku"></a> [vm\_image\_sku](#input\_vm\_image\_sku) | SKU Name of the Image to use for building the VMs required in the AVD deployment | `string` | `"win11-24h2-avd"` | no |
| <a name="input_vm_image_version"></a> [vm\_image\_version](#input\_vm\_image\_version) | What version of the image do you intend to use with the AVD deployment | `string` | `"latest"` | no |
| <a name="input_vm_license_type"></a> [vm\_license\_type](#input\_vm\_license\_type) | Type of Licensing to apply to the VM (for cost savings with licenses already purchased) | `string` | `"Windows_Client"` | no |
| <a name="input_vm_os_disk_size"></a> [vm\_os\_disk\_size](#input\_vm\_os\_disk\_size) | Size of default disk used for OS (cannot go below 130 as a value due to errors that would occur) | `string` | `"130"` | no |
| <a name="input_vm_os_disk_storage_acount_type"></a> [vm\_os\_disk\_storage\_acount\_type](#input\_vm\_os\_disk\_storage\_acount\_type) | Storage Account type for the OS Disk we wish to employ (Defaults to StandardSSD\_LRS). Some types restricted due to costs | `string` | `"StandardSSD_LRS"` | no |
| <a name="input_vm_os_disk_write_accelerator_enabled"></a> [vm\_os\_disk\_write\_accelerator\_enabled](#input\_vm\_os\_disk\_write\_accelerator\_enabled) | Enable faster OS Disk writes | `bool` | `false` | no |
| <a name="input_vm_patch_mode"></a> [vm\_patch\_mode](#input\_vm\_patch\_mode) | Configures the mode of in-guest patching for this machine. Possible values are Manual, AutomaticByOS and AutomaticByPlatform | `string` | `"Manual"` | no |
| <a name="input_vm_secure_boot_enabled"></a> [vm\_secure\_boot\_enabled](#input\_vm\_secure\_boot\_enabled) | For the AVD VMs deployed with the module, do you need secure boot enabling? This is only valid with appropriate VM images | `bool` | `false` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | SKU Size of AVD VMs to build for this deployment e.g. Standard\_B2s | `string` | `"Standard_B2s"` | no |
| <a name="input_vm_sku_size"></a> [vm\_sku\_size](#input\_vm\_sku\_size) | SKU Size of VMs to build for this deployment e.g. Standard\_B2s | `string` | `"Standard_B2s"` | no |
| <a name="input_vm_subnet_id"></a> [vm\_subnet\_id](#input\_vm\_subnet\_id) | ID of Subnet VMs will be attached to | `string` | n/a | yes |
| <a name="input_vm_tags"></a> [vm\_tags](#input\_vm\_tags) | Tags and values of tags to be used when adding to the VM specifically (Required for Backups by default in Landing Zone) | `map(string)` | <pre>{<br>  "backup": "None"<br>}</pre> | no |
| <a name="input_vm_vtpm_enabled"></a> [vm\_vtpm\_enabled](#input\_vm\_vtpm\_enabled) | Should we enabled the virtual trusted platform module with this VM (required for Windows 11+) | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_avd_vm_identities"></a> [avd\_vm\_identities](#output\_avd\_vm\_identities) | The managed IDs of every AVD VM deployed with this module (for use with assigning RBAC Roles to other Azure resources as needed) |
| <a name="output_avd_vm_ids"></a> [avd\_vm\_ids](#output\_avd\_vm\_ids) | The IDs of every AVD VM deployed with this module |
| <a name="output_avd_vm_names"></a> [avd\_vm\_names](#output\_avd\_vm\_names) | The names of every AVD VM deployed with this module |
<!-- END_TF_DOCS -->