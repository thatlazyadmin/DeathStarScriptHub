# Architecture Overview

## Introduction
This document provides an overview of the architecture for the Azure VM Provisioning Workspace. The application is designed to allow end users to request Azure Virtual Machines through a Power Apps Canvas form, closely mirroring the Azure Portal's "Create VM" experience.

## Components
The architecture consists of several key components:

1. **Power Apps Canvas Application**
   - Provides the user interface for VM provisioning.
   - Allows users to input VM specifications such as size, image, and network settings.

2. **API Layer**
   - Implemented in the `src/api` directory.
   - Handles requests for VM creation, fetching available SKUs, images, and validating names.
   - Exposes endpoints for the Power Apps Canvas application to interact with.

3. **Portal Application**
   - Built using React, located in the `src/portal` directory.
   - Contains the `CreateVMForm` component for user input and form submission.
   - Manages the overall layout and routing of the application.

4. **Utilities**
   - Utility functions in `src/utils/azureHelpers.ts` for interacting with Azure services.
   - Functions to fetch available SKUs and images, and to validate VM names.

5. **Infrastructure as Code**
   - Bicep and ARM templates located in the `infrastructure` directory.
   - Define the resources needed for VM provisioning, including the VM, NIC, and OS disk.

## Interactions
- Users interact with the Power Apps Canvas application to submit VM requests.
- The application communicates with the API layer to validate inputs and initiate VM provisioning.
- The API layer interacts with Azure services to provision the requested resources based on user specifications.
- Infrastructure templates (Bicep and ARM) are used to deploy the necessary Azure resources.

## Conclusion
This architecture provides a scalable and user-friendly solution for provisioning Azure Virtual Machines, leveraging modern web technologies and Azure's powerful infrastructure capabilities.