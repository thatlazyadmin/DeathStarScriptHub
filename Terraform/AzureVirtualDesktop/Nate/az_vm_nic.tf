# Create Network Interface for each VM to be deployed
# see reference https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface for details
# Note: These settings are explictly for AVD use only, hence no public IP assignment etc.
resource "azurerm_network_interface" "avd" {
  count = var.vm_count

  name                = "${var.resource_naming_prefix}-${format("%02d", count.index + 1)}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["cost_centre"], tags["product_environment"], tags["product_owner"], tags["project_name"]]
  }
}