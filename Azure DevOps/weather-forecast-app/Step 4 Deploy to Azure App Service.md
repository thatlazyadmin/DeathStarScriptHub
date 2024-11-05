# Step 4: Deploy to Azure App Service

## Create an Azure App Service

1. **Go to the Azure Portal**:
   - Visit the [Azure Portal](https://portal.azure.com/).

2. **Create a New App Service**:
   - In the Azure Portal, select **App Services** and create a new App Service.
   - Choose a unique name for your service, select the appropriate *Subscription*, *Resource Group*, and *Region*.

3. **Configure App Service to Use Docker**:
   - In the App Service creation settings, under *Publish*, select **Docker Container**.
   - Choose *Single Container* and set *Registry Source* to **Docker Hub**.
   - Specify your Docker Hub image details (e.g., `<your-dockerhub-username>/weather-forecast-app:latest`).

4. **Connect the App Service to Docker Hub**:
   - Enter your Docker Hub credentials to allow Azure to pull the image from your Docker Hub repository.

## Configure Continuous Deployment

1. **Enable Continuous Deployment**:
   - In the Azure Portal, navigate to your new App Service.
   - Go to *Deployment Center* and enable **Continuous Deployment**.
   - This setting ensures that any new Docker image pushed to Docker Hub will automatically update the app on Azure App Service.

By following these steps, you deploy your Docker container to Azure App Service and set up continuous deployment to keep your app updated with the latest changes.
