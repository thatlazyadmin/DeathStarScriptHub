# Step 3: Create an Azure DevOps Project and CI/CD Pipeline

## Set Up Azure DevOps Project

1. **Go to Azure DevOps**:
   - Visit [Azure DevOps](https://dev.azure.com/).

2. **Create a New Project**:
   - Create a project named `Weather Forecast CI/CD`.
   - This project will serve as the container for managing repositories, pipelines, and deployments.

## Link GitHub Repo to Azure DevOps

1. **Go to Repos**:
   - In the project, navigate to *Repos* > *Files*.
   
2. **Connect GitHub Repository**:
   - Connect your GitHub repository to Azure Repos, allowing Azure DevOps to pull the code from GitHub for pipeline automation.

## Create a Build Pipeline (CI)

1. **Go to Pipelines**:
   - Navigate to *Pipelines* > *Create Pipeline*.

2. **Select GitHub Repository**:
   - Select your GitHub repository, then choose to create a **YAML pipeline**.

3. **Sample YAML Pipeline (`azure-pipelines.yml`)**:
   - This YAML pipeline builds, tests, and pushes the Docker image to a container registry:

   ```yaml
   trigger:
     branches:
       include:
         - main

   pool:
     vmImage: 'ubuntu-latest'

   steps:
     - task: UsePythonVersion@0
       inputs:
         versionSpec: '3.x'

     - script: |
         python -m pip install --upgrade pip
         pip install -r requirements.txt
         python -m unittest discover tests
       displayName: 'Install dependencies and run tests'

     - task: Docker@2
       inputs:
         command: 'buildAndPush'
         repository: '<your-dockerhub-username>/weather-forecast-app'
         dockerfile: '**/Dockerfile'
         tags: '$(Build.BuildId)'
         containerRegistry: '<your-dockerhub-registry>'
    ```
- Replace <your-dockerhub-username> and <your-dockerhub-registry> with your Docker Hub details.

## Create a Release Pipline (CD)
1. **Go to Releases:**
    - Navigate to Pipelines > Releases and select New Pipeline.

2. **Add a Deployment Stage:**
    - Add a new stage for Azure App Service deployment.

3. **Link the Docker Image:**
    - Link the Docker image from your container registry to deploy it to Azure App Service.

By following these steps, you establish a CI/CD pipeline in Azure DevOps that automates the build, testing, and deployment of your Weather Forecast App, making it ready for production on Azure App Service.