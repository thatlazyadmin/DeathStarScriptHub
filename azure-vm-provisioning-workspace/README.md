# Azure VM Provisioning Workspace

This project provides a complete solution for provisioning Azure Virtual Machines through a user-friendly interface built with Power Apps and a web portal. The goal is to replicate the Azure Portal's "Create VM" experience, allowing end users to request VMs easily.

## Project Structure

- **src/**: Contains the source code for the application.
  - **api/**: Implements the API for VM provisioning.
    - `vmProvision.ts`: Functions for handling VM creation requests, fetching available SKUs, images, and validating names.
    - `index.ts`: Exports API routes and connects them to the main application.
  - **powerapps/**: Contains the Power Apps Canvas application for user interaction.
    - `canvasApp.msapp`: User interface for requesting VM provisioning.
  - **portal/**: Contains the web portal components.
    - **components/**: React components for the portal.
      - `CreateVMForm.tsx`: Handles user input, validation, and submission of VM creation requests.
    - **pages/**: Main entry point for the portal application.
      - `index.tsx`: Renders the CreateVMForm component.
  - **utils/**: Utility functions for Azure interactions.
    - `azureHelpers.ts`: Functions for fetching SKUs, images, and validating VM names.
  - **types/**: TypeScript types and interfaces for type safety.
    - `index.ts`: Defines types used throughout the application.

- **infrastructure/**: Contains infrastructure as code templates.
  - **bicep/**: Bicep templates for provisioning resources.
    - `vmProvisioning.bicep`: Defines resources for VM provisioning.
  - **arm/**: ARM templates as an alternative to Bicep.
    - `vmProvisioning.json`: ARM template for VM infrastructure.
  - `README.md`: Documentation for deploying infrastructure.

- **docs/**: Documentation for the project.
  - `requirements.md`: Project requirements and dependencies.
  - `architecture.md`: Architecture overview of the application.
  - `deliverables.md`: List of project deliverables.

- `package.json`: npm configuration file with dependencies and scripts.
- `tsconfig.json`: TypeScript configuration file.

## Getting Started

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd azure-vm-provisioning-workspace
   ```

2. **Install dependencies**:
   ```
   npm install
   ```

3. **Set up Azure credentials**: Ensure you have the necessary Azure credentials and permissions to provision resources.

4. **Deploy infrastructure**: Use either the Bicep or ARM templates located in the `infrastructure` directory to deploy the required resources.

5. **Run the application**:
   ```
   npm start
   ```

## Usage

- Access the Power Apps Canvas application to request VM provisioning.
- Use the web portal to fill out the VM creation form and submit requests.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.