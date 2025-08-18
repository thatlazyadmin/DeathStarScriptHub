variable "ad_domain_name" {
  description = "On Prem Active Directory Domain Name for VMs to be joined to"
  type        = string
  default     = "ugl.local"

  validation {
    condition     = can(regex("^ugl.local$|^utilitagiving.onmicrosoft.com$", var.ad_domain_name))
    error_message = "The domain can only be set to ugl.local or utilitagiving.onmicrosoft.com at this time."
  }
}

variable "ad_ou_path" {
  description = "The On-Prem Active Directory OU where all computer accounts will be created in"
  type        = string
  default     = null
}

variable "ad_domain_join_user" {
  description = "Service Account username for joining VMs to the Domain"
  type        = string
  sensitive   = true
  default     = null
}

variable "ad_domain_join_user_pw" {
  description = "Service Account password for joining VMs to the Domain"
  type        = string
  sensitive   = true
  default     = null
}

variable "avd_friendly_name" {
  description = "Friendly Name to give the AVD Workspace"
  type        = string
}

variable "avd_host_type" {
  description = "AVD Host Pool types must be either Personal or Pooled"
  type        = string
  default     = "Pooled"

  validation {
    condition     = can(regex("^Personal$|^Pooled$", var.avd_host_type))
    error_message = "The type of AVD Host Pools being created for the AVD must be either Personal or Pooled."
  }
}

variable "avd_lb_type" {
  description = "Type of Load Balancing - 'BreadthFirst' OR 'DepthFirst' OR 'Persistent' "
  type        = string
  default     = "BreadthFirst"

  validation {
    condition     = can(regex("^BreadthFirst$|^DepthFirst$|^Persistent$", var.avd_lb_type))
    error_message = "The Load Balancing required for the AVD must be set to either BreadthFirst, DepthFirst or Persistent."
  }
}

variable "avd_max_sessions" {
  description = "Enter a number value for MAX sessions PER session host"
  type        = number
  default     = 8
}

variable "entra_id_enabled" {
  description = "Will the AVD be Entra ID joined (Checking true will override AD domain join options)"
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "ID of Key Vault"
  type        = string
}

variable "host_pool_rdp_properties" {
  description = "This variable can be used to set RDP properties for the host pool being created by this module"
  type        = string
  default     = "enablecredsspsupport:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1;"
}

variable "host_pool_rdp_properties_entra_joined" {
  description = "This variable can be used to set RDP properties for the host pool being created by this module - specifically for Entra-Id joined AVD pools"
  type        = string
  default     = "targetisaadjoined:i:1;enablecredsspsupport:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1;enablerdsaadauth:i:1"
}

variable "location" {
  description = "Location of resource to manage in Azure; default is uksouth but there may be a requirement for ukwest"
  type        = string
  default     = "uksouth"

  validation {
    condition     = can(regex("^uksouth$|^ukwest$", var.location))
    error_message = "At present, all resources must be created in either uksouth or ukwest."
  }
}

variable "personal_desktop_assignment_type" {
  description = "Required if deploying 'Personal' host pool sessions - options being: Automatic or Direct. Direct is set to Default"
  type        = string
  default     = "Direct"

  validation {
    condition     = can(regex("^Direct$|^Automatic$", var.personal_desktop_assignment_type))
    error_message = "You must choose either 'Automatic' or 'Direct' (Case sensitive)"
  }
}

variable "provision_vm_agent" {
  description = "Provision VM agent (VM Tools)"
  type        = bool
  default     = true
}

variable "rbac_desktop_user_group_ids" {
  description = "RBAC Role Assignment for Desktop Users Groups via their object IDs"
  type        = set(string)
  default     = []
}

variable "rbac_avd_support_group_ids" {
  description = "RBAC Role Assignment for AVD Support Groups via their object IDs"
  type        = set(string)
  default     = []
}

variable "rbac_rg_entra_vm_admin_group_ids" {
  description = "RBAC Role Assignment for Admin Groups via their object IDs to log onto VMs with Admin permissions when VMs are joined to Entra ID"
  type        = set(string)
  default     = []
}

variable "rbac_rg_contributor_group_ids" {
  description = "RBAC Role Assignment for Admin Groups via their object IDs (Only for deployments outside of Utilita's Landing Zone due to policy management)"
  type        = set(string)
  default     = []
}

variable "resource_group_name" {
  description = "Resource Group Name where all AVD resources will be created"
  type        = string
}

variable "resource_group_id" {
  description = "Resource Group id where all AVD resources will be created (needed for RBAC)"
  type        = string
}

variable "resource_naming_prefix" {
  description = "Prefix to attach to all resources being created here"
  type        = string
}

variable "session_desktop_friendly_name" {
  description = "Friendly Name for the default Session Desktop Link that appears in the Remote Desktop App"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags and values of tags to be used"
  type        = map(string)
  default     = {}
}

variable "vm_patch_mode" {
  description = "Configures the mode of in-guest patching for this machine. Possible values are Manual, AutomaticByOS and AutomaticByPlatform"
  type        = string
  default     = "Manual"

  validation {
    condition     = can(regex("^Manual$|^AutomaticByPlatform$|^AutomaticByOS$", var.vm_patch_mode))
    error_message = "The patch_mode variable can only be set to Manual, AutomaticByPlatform or AutomaticByOS. Case sensitive"
  }
}

variable "vm_allow_extension_operations" {
  description = "Should Extension Operations be allowed on this Virtual Machine?"
  type        = bool
  default     = true
}

variable "vm_enable_automatic_updates" {
  description = "Enable automatic patching via Azure (should be false unless otherwise stated, as patch management carried out elsewhere)"
  type        = bool
  default     = false
}

variable "vm_admin_user" {
  description = "Username of the Admin User for the VMs built"
  type        = string
  default     = "avdroot"
}

variable "vm_autoshutdown_enabled" {
  description = "Do we want this VM to auto-shutdown on a daily basis?"
  type        = bool
  default     = true
}

variable "vm_autoshutdown_time" {
  description = "Time of day we wish to perform the autoshutdown operation e.g. 2200, 1930, 0800"
  type        = string
  default     = "2000"
}

variable "vm_autoshutdown_timezone" {
  description = "What timezone is being referenced for shutting down the VM at the right time"
  type        = string
  default     = "GMT Standard Time"
}

variable "vm_count" {
  description = "Specify the number of VMs to be created for this AVD deployment"
  type        = number
  default     = 1
}

variable "vm_image_offer" {
  description = "Offer Name to use with building the VMs required in the AVD deployment"
  type        = string
  default     = "Windows-11"
}

variable "vm_hotpatching_enabled" {
  description = "should hotpatching be enabled for this?"
  type        = bool
  default     = false
}

variable "vm_image_publisher" {
  description = "Publisher Image Name to use with building the VMs required in the AVD deployment"
  type        = string
  default     = "MicrosoftWindowsDesktop"
}

variable "vm_image_sku" {
  description = "SKU Name of the Image to use for building the VMs required in the AVD deployment"
  type        = string
  default     = "win11-24h2-avd" # Must be an image with AVD in to ensure that FSLogix is already installed
}

variable "vm_image_version" {
  description = "What version of the image do you intend to use with the AVD deployment"
  type        = string
  default     = "latest"
}

variable "vm_license_type" {
  description = "Type of Licensing to apply to the VM (for cost savings with licenses already purchased)"
  type        = string
  default     = "Windows_Client"

  validation {
    condition     = can(regex("^None$|^Windows_Client$", var.vm_license_type))
    error_message = "The license_type variable can only be set to None or Windows_Client within the AVD module. Case sensitive"
  }
}

variable "vm_os_disk_size" {
  description = "Size of default disk used for OS (cannot go below 130 as a value due to errors that would occur)"
  type        = string
  default     = "130"
}

variable "vm_os_disk_storage_acount_type" {
  description = "Storage Account type for the OS Disk we wish to employ (Defaults to StandardSSD_LRS). Some types restricted due to costs"
  type        = string
  default     = "StandardSSD_LRS"

  validation {
    condition     = can(regex("^Standard_LRS$|^StandardSSD_LRS$|^Premium_LRS$", var.vm_os_disk_storage_acount_type))
    error_message = "Only Storage Account types allowed are Standard_LRS, StandardSSD_LRS and Premium_LRS at this time. Case sensitive"
  }
}

variable "vm_os_disk_write_accelerator_enabled" {
  description = "Enable faster OS Disk writes"
  type        = bool
  default     = false
}

variable "vm_secure_boot_enabled" {
  description = "For the AVD VMs deployed with the module, do you need secure boot enabling? This is only valid with appropriate VM images"
  type        = bool
  default     = false
}

variable "vm_sku_size" {
  description = "SKU Size of VMs to build for this deployment e.g. Standard_B2s"
  type        = string
  default     = "Standard_B2s" # default to smallest usable sku if not specified
}

variable "vm_size" {
  description = "SKU Size of AVD VMs to build for this deployment e.g. Standard_B2s"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_subnet_id" {
  description = "ID of Subnet VMs will be attached to"
  type        = string
}

variable "vm_tags" {
  description = "Tags and values of tags to be used when adding to the VM specifically (Required for Backups by default in Landing Zone)"
  type        = map(string)
  default = {
    backup = "None"
  }
}

variable "vm_vtpm_enabled" {
  description = "Should we enabled the virtual trusted platform module with this VM (required for Windows 11+)"
  type        = bool
  default     = true
}
