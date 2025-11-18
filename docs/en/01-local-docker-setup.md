# Task 1: Local Docker Setup and Container Deployment

## Overview

In this task, you'll learn the fundamentals of containerization by:

- Inspecting the workshop applications (Frontend and WebApi)
- Understanding Dockerfiles and how they define container images
- Building Docker images locally
- Running containers from your built images
- Testing the application stack running in containers

**Estimated Time:** 30 minutes

---

## Prerequisites

Before starting, ensure you have:

- Docker Desktop or Rancher Desktop (or similiar) installed and running
- PowerShell Core
- Git (to clone or access the workshop repository)
- A code editor (VS Code recommended)

### Verify Docker Installation

Open PowerShell and run:

```powershell
docker --version
docker ps
```

If Docker is not running, start Docker Desktop or Rancher Desktop and wait for it to be ready.

---

## Part 1: Explore the Applications

### 1.1 Understanding the Frontend Application

Navigate to the Frontend application folder:

```powershell
cd src\Frontend
```

**Explore the key files:**

1. **index.html** - The main HTML page for the shopping frontend
2. **app.js** - JavaScript that calls the backend API
3. **nginx.conf** - Configuration for the NGINX web server
4. **Dockerfile** - Instructions for building the container image

**Open and review the Dockerfile:**

```powershell
code Dockerfile
```

**Key observations:**

- It uses NGINX as the base image
- Copies static files into the container
- Exposes port 80
- Uses a custom entrypoint script for configuration

### 1.2 Understanding the WebApi Application

Navigate to the WebApi application folder:

```powershell
cd ..\WebApi
```

**Explore the key files:**

1. **Program.cs** - The main C# API application
2. **WebApi.csproj** - Project file defining dependencies
3. **Dockerfile** - Instructions for building the container image

**Open and review the Dockerfile:**

```powershell
code Dockerfile
```

**Key observations:**

- It uses multi-stage build (SDK for building, runtime for running)
- Copies and restores dependencies first (Docker layer caching)
- Builds the application
- Creates a lean runtime image
- Exposes port 8080

---

## Part 2: Build Docker Images

Now that you understand the applications, let's build container images.

### 2.1 Build the WebApi Image

From the `src\WebApi` directory:

```powershell
.\build.ps1
```

**What happens:**

- The script automatically manages versioning (starts at 1.0)
- Builds a Docker image named `container-workshop/webapi:1.0`
- Shows you the Docker command being executed
- Lists the created image

**Verify the image was created:**

```powershell
docker images | Select-String "webapi"
```

You should see your newly built image with tag `1.0`.

### 2.2 Build the Frontend Image

Navigate to the Frontend directory:

```powershell
cd ..\Frontend
```

Build the image:

```powershell
.\build.ps1
```

**What happens:**

- Similar to WebApi, the script manages versioning automatically
- Builds a Docker image named `container-workshop/shop:1.0`

**Verify the image was created:**

```powershell
docker images | Select-String "shop"
```

### 2.3 Understanding Docker Images

List all your workshop images:

```powershell
docker images | Select-String "container-workshop"
```

**Key concepts:**

- **Image Name**: Identifies the application (e.g., `container-workshop/webapi`)
- **Tag**: Version identifier (e.g., `1.0`)
- **Image ID**: Unique identifier for the image
- **Size**: How much disk space the image uses

---

## Part 3: Run Containers Locally

Now let's run the applications as containers.

### 3.1 Start the WebApi Container

From the `src\WebApi` directory:

```powershell
.\start.ps1
```

**What happens:**

- Checks if a container named "webapi" already exists
- Removes old containers if they exist
- Starts a new container from your built image
- Maps port 5000 (host) → 8080 (container)

**Verify the container is running:**

```powershell
docker ps
```

You should see a container named `webapi` with status `Up`.

**Test the API:**

Open your browser and navigate to:

- <http://localhost:5000/pizzas>

You should see a JSON response with pizza data.

### 3.2 Start the Frontend Container

Navigate to the Frontend directory:

```powershell
cd ..\Frontend
```

Start the container:

```powershell
.\start.ps1
```

**What happens:**

- Starts a container named "frontend"
- Maps port 8080 (host) → 80 (container)
- Configures the frontend to call the API at the backend URL

**Verify the container is running:**

```powershell
docker ps
```

You should see both `frontend` and `webapi` containers running.

**Test the full application:**

Open your browser and navigate to:

- <http://localhost:8080>

You should see the shopping application with pizzas loaded from the API.

---

## Part 4: Explore Running Containers

### 4.1 View Container Logs

**View WebApi logs:**

```powershell
docker logs webapi
```

You should see ASP.NET Core startup messages and any HTTP requests.

**View Frontend logs:**

```powershell
docker logs frontend
```

You should see NGINX startup messages.

**Follow logs in real-time:**

```powershell
docker logs -f webapi
```

Press `Ctrl+C` to stop following logs.

### 4.2 Inspect Container Details

**Inspect the WebApi container:**

```powershell
docker inspect webapi
```

This shows detailed configuration including:

- Network settings
- Port mappings
- Environment variables
- Volume mounts

**View container resource usage:**

```powershell
docker stats --no-stream
```

This shows CPU, memory, and network usage for all running containers.

### 4.3 Execute Commands Inside Containers

**Open a shell in the WebApi container:**

```powershell
docker exec -it webapi /bin/bash
```

Inside the container, you can explore:

```bash
# Check the working directory
pwd

# List files
ls -la

# Check the .NET version
dotnet --version

# Exit the container
exit
```

**Open a shell in the Frontend container:**

```powershell
docker exec -it frontend /bin/sh
```

Inside the container:

```bash
# View NGINX configuration
cat /etc/nginx/nginx.conf

# Check running processes
ps aux

# Exit
exit
```

---

## Part 5: Testing and Troubleshooting

### 5.1 Make Changes and Rebuild

Let's make a change to see the versioning in action.

**Edit the WebApi to add a new pizza:**

Open `src\WebApi\Program.cs` and find the pizzas list. Add a new pizza:

```csharp
new Pizza(
    7,
    "Calzone",
    "Folded pizza with ham, mushrooms, and mozzarella",
    ["Tomato Sauce", "Mozzarella", "Ham", "Mushrooms"]
)
```

**Rebuild the image:**

```powershell
.\build.ps1
```

Notice the version increments to `1.1`.

**Restart the container with the new version:**

```powershell
.\start.ps1
```

**Test the change:**

Visit <http://localhost:5000/pizzas> and verify your new pizza appears.

### 5.2 Stop Containers

**Stop all running containers:**

```powershell
docker stop webapi frontend
```

**Remove containers:**

```powershell
docker rm webapi frontend
```

**Verify they're stopped:**

```powershell
docker ps -a
```

### 5.3 Common Issues

**Issue: Port already in use**

```
Error: Bind for 0.0.0.0:5000 failed: port is already allocated
```

**Solution:** Stop the existing container or use a different port.

**Issue: Container exits immediately**

```
docker ps shows nothing, but docker ps -a shows exited container
```

**Solution:** Check logs with `docker logs <container-name>` to see the error.

**Issue: Cannot connect to Docker**

```
error during connect: This error may indicate that the docker daemon is not running
```

**Solution:** Start Docker Desktop.

---

## Summary

In this task, you've learned how to:

✅ Inspect application structure and Dockerfiles  
✅ Build Docker images with automated versioning  
✅ Run containers locally with port mapping  
✅ Test and debug running containers  
✅ View logs and inspect container details  
✅ Execute commands inside containers  
✅ Make changes and rebuild images  

**Next Step:** [Task 2: Deploy to Azure App Service](02-app-service-deployment.md)

In the next task, you'll deploy the Azure infrastructure using Bicep, push your container images to Azure Container Registry, and configure your App Service to use those images.
