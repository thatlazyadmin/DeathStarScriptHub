# Step 2: Containerize the App with Docker

## Create a Dockerfile

1. **Add a Dockerfile**:
   - Place a `Dockerfile` in the root directory of your project to define the container configuration.

2. **Sample Dockerfile for Python**:
   - This Dockerfile sets up the environment for a Python app using Flask:
   
   ```dockerfile
   # Use the official Python image
   FROM python:3.9-slim

   # Set the working directory
   WORKDIR /app

   # Install dependencies
   COPY requirements.txt .
   RUN pip install -r requirements.txt

   # Copy the app code
   COPY . .

   # Expose the port Flask will run on
   EXPOSE 5000

   # Run the app
   CMD ["python", "app.py"]
    ```

### Build and Test Locally
1. **Build the Docker Image:**
    - Run the following command to build the Docker image for your app:
```bash

docker build -t weather-forecast-app .
```
2. **Run the Docker Container Locally:**
    - Test the container by running it on your local machine:
```bash
    docker run -p 5000:5000 weather-forecast-app
```
 - Your app should now be accessible at http://localhost:5000

 ### Push to Docker Hub (Optional)
 1. **Tag the Docker Images"**
    - Tag the image to prepare it for pushing to Docker Hub:
```bash
docker tag weather-forecast-app <your-dockerhub-username>/weather-forecast-app
```
2. **Push to Docker Hub:**
    - Push the tagged image to your Docker Hub repository:

```bash
docker push <your-dockerhub-username>/weather-forecast-app
```
By containerizing the app with Docker, you ensure a consistent environment that can be deployed easily across various platforms, simplifying the deployment process for your Weather Forecast App.
