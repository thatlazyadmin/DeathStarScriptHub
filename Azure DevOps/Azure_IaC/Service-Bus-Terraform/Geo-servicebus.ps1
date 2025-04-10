##This Terraform script provisions the following Azure resources:


##STEP 1 - LOGIN IN AZURE####################################################
provider "azurerm" {
    features {}
  
    skip_provider_registration = true
  }
  
  
  ###VARIABLES
  ##STEP 2 - CONFIGURE YOUR TAGS ###############################################
  variable "tags" {
    type = map(string)
    default = {
      CustomerName          = "Client01"
      AutoShutdownSchedule  = "None"
      Environment           = "Sandbox"
      Role                  = "Service Bus"
    }
  }
  
  
  #STEP 3 - CONFIGURE YOUR RESOURCE GROUP #####################################
  #create resource group
  resource "azurerm_resource_group" "example" {
    name     = "allen-tf-servicebus-ha-rg"
    location = "southafricanorth"
    tags     = var.tags
  }
  
  #STEP 4 - CONFIGURE YOUR PRIMARY SERVICE BUS #################################
  resource "azurerm_servicebus_namespace" "primary" {
    name                			= "servicebus-primary"
    location            			= azurerm_resource_group.example.location
    resource_group_name 			= azurerm_resource_group.example.name
    sku                 			= "Premium"
    capacity            			= "1"
    tags     	      			= var.tags
    minimum_tls_version 			= 1.2
    premium_messaging_partitions 		= 1
    local_auth_enabled			= true
    zone_redundant			= true
  }
  
  #STEP 5 - CONFIGURE YOUR SECONDARY SERVICE BUS #################################
  resource "azurerm_servicebus_namespace" "secondary" {
    name                			= "servicebus-secondary"
    location            			= "westeurope"
    resource_group_name 			= azurerm_resource_group.example.name
    sku                 			= "Premium"
    capacity            			= "1"
    tags     	      			= var.tags
    minimum_tls_version 			= 1.2
    premium_messaging_partitions  	= 1
    local_auth_enabled			= true
    zone_redundant			= true
  }
  
  #STEP 6 - CONFIGURE THE SHARED ACCESS POLICY #################################
  resource "azurerm_servicebus_namespace_authorization_rule" "example" {
    name         = "disaster-recover-rule"
    namespace_id = azurerm_servicebus_namespace.primary.id
  
    listen = true
    send   = true
    manage = false
  }
  
  #STEP 7 - CONFIGURE THE DISASTER RECOVERY RULE #################################
  resource "azurerm_servicebus_namespace_disaster_recovery_config" "config" {
    name                        = "servicebus-alias-name"
    primary_namespace_id        = azurerm_servicebus_namespace.primary.id
    partner_namespace_id        = azurerm_servicebus_namespace.secondary.id
    alias_authorization_rule_id = azurerm_servicebus_namespace_authorization_rule.example.id
  }
  
  
  
  
  ##STEP 8A - DEFINE YOUR FIRST VIRTUAL NETWORK ############################################
  
  resource "azurerm_resource_group" "vnet01rg" {
    name     = "allen-infra-southafricanorth"
    location = "South Africa North"
    tags     = var.tags
  }
  
  
  resource "azurerm_virtual_network" "vnet01" {
    name                = "vnet01-san"
    resource_group_name = azurerm_resource_group.vnet01rg.name
    location			  = azurerm_resource_group.vnet01rg.location
    address_space       = ["10.0.0.0/16"]
    tags     = var.tags
  }
  
  resource "azurerm_subnet" "sub1vnet1" {
    name                 = "sub1-private-endpoints"
    virtual_network_name = azurerm_virtual_network.vnet01.name
    resource_group_name  = azurerm_virtual_network.vnet01.resource_group_name
    address_prefixes     = ["10.0.0.0/26"]
  }
  
  
  ##STEP 8B - DEFINE YOUR SECOND VIRTUAL NETWORK ############################################
  
  resource "azurerm_resource_group" "vnet02rg" {
    name     = "allen-infra-southafricanorth"
    location = "South Africa North"
    tags     = var.tags
  }
  
  resource "azurerm_virtual_network" "vnet02" {
    name                = "vnet02-san"
    resource_group_name = azurerm_resource_group.vnet02rg.name
    location			  = azurerm_resource_group.vnet02rg.location
    address_space       = ["20.0.0.0/16"]
    tags     = var.tags
  }
  
  resource "azurerm_subnet" "sub1vnet2" {
    name                 = "sub1-private-endpoints"
    virtual_network_name = azurerm_virtual_network.vnet02.name
    resource_group_name  = azurerm_virtual_network.vnet02.resource_group_name
    address_prefixes     = ["20.0.0.0/26"]
  }
  
  
  
  
  #STEP 9.1 - CONFIGURE YOUR 1/4 PRIVATE ENDPOINTS ####################################
  resource "azurerm_private_endpoint" "privendpoint1" {
    name                = "vnet01-servicebus-primary-private-endpoint"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    subnet_id           = azurerm_subnet.sub1vnet1.id
  
    private_service_connection {
      name                           = "vnet01-servicebus-primary-privateserviceconnection"
      private_connection_resource_id = azurerm_servicebus_namespace.primary.id
      is_manual_connection           = false
      subresource_names              = ["namespace"]
    }
  
    tags = var.tags
  }
  
  
  #STEP 9.2 - CONFIGURE YOUR 2/4 PRIVATE ENDPOINTS ####################################
  resource "azurerm_private_endpoint" "privendpoint2" {
    name                = "vnet01-servicebus-secondary-private-endpoint"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    subnet_id           = azurerm_subnet.sub1vnet1.id
  
    private_service_connection {
      name                           = "vnet01-servicebus-secondary-privateserviceconnection"
      private_connection_resource_id = azurerm_servicebus_namespace.secondary.id
      is_manual_connection           = false
      subresource_names              = ["namespace"]
    }
  
    tags = var.tags
  }
  
  
  #STEP 9.3 - CONFIGURE YOUR 3/4 PRIVATE ENDPOINTS ####################################
  resource "azurerm_private_endpoint" "privendpoint3" {
    name                = "vnet02-servicebus-primary-private-endpoint"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    subnet_id           = azurerm_subnet.sub1vnet2.id
  
    private_service_connection {
      name                           = "vnet02-servicebus-primary-privateserviceconnection"
      private_connection_resource_id = azurerm_servicebus_namespace.primary.id
      is_manual_connection           = false
      subresource_names              = ["namespace"]
    }
  
    tags = var.tags
  }
  
  
  #STEP 9.4 - CONFIGURE YOUR 4/4 PRIVATE ENDPOINTS ####################################
  resource "azurerm_private_endpoint" "privendpoint4" {
    name                = "vnet02-servicebus-secondary-private-endpoint"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    subnet_id           = azurerm_subnet.sub1vnet2.id
  
    private_service_connection {
      name                           = "vnet02-servicebus-secondary-privateserviceconnection"
      private_connection_resource_id = azurerm_servicebus_namespace.secondary.id
      is_manual_connection           = false
      subresource_names              = ["namespace"]
    }
  
    tags = var.tags
  }
  
  
  ####CONFIGURE MONITORING
  ##STEP 10 - PROVISION A LOG ANALYTICS WORKSPACE
  
  
  resource "azurerm_resource_group" "law01rg" {
    name     = "allen-monitoring"
    location = "South Africa North"
    tags     = var.tags
  }
  
  
  
  resource "azurerm_log_analytics_workspace" "law01" {
    name                = "allen-monitoring"
    location            = "South Africa North"
    resource_group_name = azurerm_resource_group.law01rg.name
    sku                 = "PerGB2018"
    retention_in_days   = 30
    tags     			  = var.tags
  }
  
  ##########