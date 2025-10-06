terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  required_version = ">= 1.2"
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-avd-full"
  location = "eastus"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-avd-full"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.20.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-avd-full"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.1.0/24"]

  delegation {
    name = "avd_delegation"

    service_delegation {
      name    = "Microsoft.DesktopVirtualization/sessionHosts"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "nic-avd-sessionhost"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Hostpool ARM template deployment (you must provide this ARM JSON file)
resource "azurerm_template_deployment" "hostpool" {
  name                = "avd-hostpool-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_body       = file("hostpool-template.json")

  parameters = {
    hostpoolName = "avd-full-hostpool"
    location     = azurerm_resource_group.rg.location
  }
}

# Virtual Machine Session Host
resource "azurerm_virtual_machine" "sessionhost" {
  name                  = "avd-sessionhost01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS2_v2"

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name              = "osdisk-avd-sessionhost01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "22h2-pro"
    version   = "latest"
  }

  os_profile {
    computer_name  = "avd-sessionhost01"
    admin_username = "azureuser"
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  tags = {
    environment = "avd"
  }
}

# Domain Join Extension
resource "azurerm_virtual_machine_extension" "domain_join" {
  name                 = "domainJoin"
  virtual_machine_id   = azurerm_virtual_machine.sessionhost.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = jsonencode({
    Name     = var.domain_name
    OUPath   = var.ou_path
    User     = var.domain_join_user
    Restart  = "true"
    Password = var.domain_join_password
  })
}

# Custom Script Extension - install AVD Agent
resource "azurerm_virtual_machine_extension" "avd_agent_install" {
  name                 = "avdAgentInstall"
  virtual_machine_id   = azurerm_virtual_machine.sessionhost.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri 'https://aka.ms/avd-agent' -OutFile 'C:\\avd-agent.msi'; Start-Process msiexec.exe -ArgumentList '/i C:\\avd-agent.msi /quiet /norestart' -Wait\""
  })
}

# Role Assignment for session host
resource "azurerm_role_assignment" "avd_sessionhost_role" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Desktop Virtualization Session Host"
  principal_id         = azurerm_virtual_machine.sessionhost.identity.principal_id
}

# Variables for sensitive data
variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "AD Domain name"
  type        = string
}

variable "ou_path" {
  description = "OU path for domain join, e.g. OU=computers,DC=domain,DC=com"
  type        = string
}

variable "domain_join_user" {
  description = "User for domain join, e.g. domain\\joinuser"
  type        = string
}

variable "domain_join_password" {
  description = "Password for domain join user"
  type        = string
  sensitive   = true
}
