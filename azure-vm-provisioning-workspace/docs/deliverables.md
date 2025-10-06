# Deliverables for Azure VM Provisioning Workspace

## Project Deliverables

1. **API Implementation**
   - A fully functional API for provisioning virtual machines, including:
     - Endpoint for creating virtual machines.
     - Endpoint for fetching available SKUs.
     - Endpoint for fetching available images.
     - Validation logic for VM names.

2. **Power Apps Canvas Application**
   - A Power Apps Canvas application (`canvasApp.msapp`) that provides a user-friendly interface for requesting VM provisioning.
   - The application includes:
     - Input fields for VM configuration (name, size, image, etc.).
     - Validation messages for user input.
     - Submission functionality to the API.

3. **Portal Application**
   - A React-based portal application that mirrors the Azure Portal's "Create VM" experience, including:
     - A `CreateVMForm` component for user input.
     - Integration with the API for VM provisioning.
     - Proper error handling and user feedback.

4. **Utility Functions**
   - A set of utility functions (`azureHelpers.ts`) for interacting with Azure services, including:
     - Functions to fetch available SKUs and images.
     - Functions to validate VM names against Azure naming conventions.

5. **Infrastructure as Code**
   - Bicep and ARM templates for provisioning the necessary Azure resources, including:
     - Virtual Machine.
     - Network Interface Card (NIC).
     - OS Disk.
   - Documentation on how to deploy the infrastructure using these templates.

6. **Documentation**
   - Comprehensive documentation covering:
     - Project requirements (`requirements.md`).
     - Architectural overview (`architecture.md`).
     - Detailed deliverables and functionalities (`deliverables.md`).
     - Setup instructions and usage guidelines in the main `README.md`.

7. **TypeScript Types and Interfaces**
   - Defined TypeScript types and interfaces for ensuring type safety across the application.

## Expected Outputs
- A fully operational Azure VM provisioning system that allows end users to request virtual machines through a Power Apps interface.
- Clear and concise documentation for developers and users.