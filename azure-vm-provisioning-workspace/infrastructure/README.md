# Azure VM Provisioning Workspace Infrastructure

This directory contains the infrastructure code for provisioning Azure Virtual Machines using both Bicep and ARM templates.

## Bicep Template

- **vmProvisioning.bicep**: This file defines the infrastructure resources required for provisioning virtual machines, including the virtual machine itself, network interface, and operating system disk. It is recommended to use this template for a more concise and readable infrastructure as code.

## ARM Template

- **vmProvisioning.json**: This file serves as an alternative to the Bicep template. It provides the same functionality but in the ARM template format. Use this if you prefer working with ARM templates or if your organization has specific requirements for ARM.

## Deployment Instructions

To deploy the infrastructure, you can use either the Bicep or ARM template. Ensure you have the Azure CLI installed and configured with the necessary permissions to create resources in your Azure subscription.

### Using Bicep

1. Install the Bicep CLI if you haven't already.
2. Run the following command to deploy the Bicep template:

   ```bash
   az deployment group create --resource-group <your-resource-group> --template-file bicep/vmProvisioning.bicep
   ```

### Using ARM

1. Run the following command to deploy the ARM template:

   ```bash
   az deployment group create --resource-group <your-resource-group> --template-file arm/vmProvisioning.json
   ```

## Additional Resources

Refer to the documentation in the `docs` directory for more information on project requirements, architecture, and deliverables.