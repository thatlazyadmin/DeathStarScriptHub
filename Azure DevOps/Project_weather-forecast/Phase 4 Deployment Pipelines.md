# Phase 4: Deployment Pipelines

## Release Pipelines for Continuous Delivery (CD)

- **Definition**: Continuous Delivery (CD) automates the deployment process to various environments, ensuring fast and reliable releases with minimal manual intervention.
- **Use Case**: CD streamlines release management, reducing deployment risks and providing consistency across environments.

### Lab Task: Configure a Release Pipeline with Environment Stages

#### Step-by-Step:

1. **Create a New Release Pipeline**:
   - In Azure DevOps, navigate to *Pipelines* > *Releases* > *New Pipeline*.

2. **Define Stages**:
   - Create deployment stages such as **Dev**, **QA**, and **Prod** to represent different environments.

3. **Add Deployment Tasks**:
   - In each stage, add tasks that deploy the application to the appropriate environment, such as:
     - *Azure App Service*: Deploys a web app to Azure.
     - *Virtual Machine (VM)*: Deploys an application to a virtual machine.
   
4. **Set Up Stage Approvals**:
   - Configure approvals between stages to ensure control over releases, particularly for production:
     - Go to each stage, and under **Pre-deployment conditions**, set up an approval to require a review before moving to the next stage.

---

## Infrastructure as Code (IaC) with ARM/Bicep

- **Definition**: Infrastructure as Code (IaC) enables the management of infrastructure (e.g., networks, VMs, databases) using configuration files, ensuring consistency across deployments.
- **Use Case**: IaC provides reproducibility and version control for infrastructure, making it easier to maintain environments.

### Lab Task: Deploy Resources Using ARM or Bicep Templates

#### Step-by-Step:

1. **Create an ARM or Bicep Template**:
   - Write a template file (`infrastructure.bicep` or `template.json`) that defines the resources you want to deploy, such as an Azure VM, Azure SQL Database, or Azure App Service.

2. **Deploy the Template with a Pipeline**:
   - Use an Azure DevOps pipeline to deploy the template. Here’s a YAML example to deploy a Bicep file:

   ```yaml
   - task: AzureResourceManagerTemplateDeployment@3
     inputs:
       deploymentScope: 'Resource Group'
       azureResourceManagerConnection: '<Your Connection>'
       csmFile: 'infrastructure.bicep'
       resourceGroupName: '<Resource Group>'
       location: '<Location>'
    ```
- Replace placeholders with:
    - <Your Connection>: The name of your Azure DevOps service connection.
    - <Resource Group>: The resource group for the deployment.
    - <Location>: The Azure region (e.g., East US).

This configuration allows you to deploy resources consistently across environments using ARM/Bicep, helping manage infrastructure as code in a version-controlled and reproducible way.
