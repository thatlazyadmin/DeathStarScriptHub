# Phase 8: Advanced DevOps Practices

## Containerization and AKS

- **Definition**: Containers provide a standardized environment for applications, ensuring consistency in deployment across various platforms. Azure Kubernetes Service (AKS) is a managed Kubernetes service in Azure that orchestrates and manages containers at scale.
- **Use Case**: Containers and AKS simplify deployment processes, especially for applications designed with microservices, enabling reliable scaling and resource management.

### Lab Task: Deploy a Docker Container to AKS

#### Step-by-Step:

1. **Containerize the Application with Docker**:
   - Create a `Dockerfile` in your application’s root directory to define the container configuration.
   - Build and test the Docker container locally:
     ```bash
     docker build -t myapp:latest .
     docker run -p 8080:8080 myapp:latest
     ```
   - Log in to Azure and push the container to Azure Container Registry (ACR):
     ```bash
     az login
     az acr login --name <YourACRName>
     docker tag myapp:latest <YourACRName>.azurecr.io/myapp:latest
     docker push <YourACRName>.azurecr.io/myapp:latest
     ```

2. **Create an AKS Cluster in Azure**:
   - Go to the [Azure Portal](https://portal.azure.com/), navigate to *Kubernetes services*, and create a new AKS cluster:
     - Specify the *Resource Group*, *Cluster Name*, and *Region*.
     - Choose the appropriate *Node Size* and *Node Count* based on your app’s needs.
   - Connect your AKS cluster to Azure Container Registry (ACR) to allow it to pull images:
     ```bash
     az aks update -n <YourAKSClusterName> -g <ResourceGroupName> --attach-acr <YourACRName>
     ```

3. **Deploy the Container to AKS from ACR Using a Pipeline**:
   - Set up a deployment pipeline in Azure DevOps to automate the container deployment to AKS:
     - Define the pipeline to pull the Docker image from ACR and deploy it to the AKS cluster.
     - Example YAML pipeline for deploying to AKS:
       ```yaml
       trigger:
         branches:
           include:
             - main

       pool:
         vmImage: 'ubuntu-latest'

       steps:
         - task: KubectlInstaller@0
           inputs:
             kubectlVersion: 'latest'

         - task: Kubernetes@1
           inputs:
             connectionType: 'Azure Resource Manager'
             azureSubscription: '<YourAzureSubscription>'
             azureResourceGroup: '<YourResourceGroup>'
             kubernetesCluster: '<YourAKSClusterName>'
             namespace: 'default'
             command: 'apply'
             useConfigurationFile: true
             configuration: 'deployment.yaml'
       ```

       - Replace placeholders with your actual Azure subscription, resource group, and AKS cluster name.
       - Ensure you have a `deployment.yaml` file in your repository to define the container deployment on AKS.

By containerizing your app and deploying it to AKS, you enable scalable and consistent application delivery. The integration of ACR and AKS in the CI/CD pipeline also streamlines deployment and scaling for microservices-based architectures.
