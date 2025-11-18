# Container Workshop

A hands-on workshop for learning container technologies and Azure deployment strategies. This workshop guides you through containerizing applications, building Docker images, and deploying to various Azure services.

## 🎯 Workshop Overview

This workshop teaches you how to:

- Containerize applications using Docker
- Build and run containers locally
- Deploy containers to Azure App Service
- Deploy containers to Azure Container Apps
- Deploy containers to Azure Kubernetes Service (AKS)

## 📚 Workshop Tasks

Complete the tasks in order to build your skills progressively:

1. **[Local Docker Setup](docs/en/01-local-docker-setup.md)** - Learn Docker basics, build images, and run containers locally
2. **[Azure App Service Deployment](docs/en/02-app-service-deployment.md)** - Deploy containers to Azure App Service with ACR
3. **[Azure Container Apps Deployment](docs/en/03-container-apps-deployment.md)** - Deploy to serverless Container Apps with auto-scaling
4. **[Azure Kubernetes Service (AKS) Deployment](docs/en/04-aks-deployment.md)** - Deploy to AKS for production-grade orchestration

## 🏗️ Folder Structure

```text
workshop.containers/
├── docs/                           # Workshop documentation
│   └── en/                         # English language tasks
├── eng/                            # Engineering and deployment resources
│   ├── infrastructure/             # Bicep infrastructure-as-code
│   │   ├── main.bicep              # Main infrastructure template
│   │   ├── main-app-services.bicep # App Service specific template
│   │   ├── main-container-apps.bicep # Container Apps specific template
│   │   ├── main-aks.bicep          # AKS specific template
│   │   ├── deploy.ps1              # Deployment script
│   │   ├── destroy.ps1             # Clean-up script
│   │   └── modules/                # Reusable Bicep modules
│   └── kubernetes/                 # Kubernetes manifests
│       ├── api-deployment.yaml     # API deployment definition
│       ├── frontend-deployment.yaml # Frontend deployment definition
│       ├── ingress.yaml            # Ingress configuration
│       └── deploy.ps1              # Kubernetes deployment script
├── scripts/                        # Utility scripts
│   └── utils.ps1                   # PowerShell utilities
├── src/                            # Application source code
│   ├── Frontend/                   # Frontend application (nginx + vanilla JS)
│   │   ├── index.html              # Main HTML page
│   │   ├── app.js                  # JavaScript application logic
│   │   ├── styles.css              # Application styles
│   │   ├── nginx.conf              # Nginx configuration
│   │   ├── docker-entrypoint.sh    # Container entrypoint script
│   │   ├── Dockerfile              # Frontend container definition
│   │   ├── build.ps1               # Build script
│   │   ├── deploy.ps1              # Deployment script
│   │   └── start.ps1               # Local development script
│   └── WebApi/                     # Backend API (.NET 9)
│       ├── Program.cs              # API entry point
│       ├── WebApi.csproj           # .NET project file
│       ├── appsettings.json        # Application configuration
│       ├── Dockerfile              # API container definition
│       ├── build.ps1               # Build script
│       ├── deploy.ps1              # Deployment script
│       └── start.ps1               # Local development script
├── check-prerequisites.ps1         # Prerequisites checker
├── global.json                     # .NET SDK version specification
└── Workshop.sln                    # Visual Studio solution file
```

## 🍕 Applications

The workshop includes two microservices that work together to create a pizza ordering system:

### WebApi (Backend)

A **REST API** built with **.NET 9** (ASP.NET Core Minimal APIs) that provides:

- **Pizza Catalog**: GET `/pizzas` - Returns a list of available pizzas with descriptions and ingredients
- **Basket Management**:
  - GET `/basket` - Retrieve current basket
  - POST `/basket` - Add items to basket
  - PUT `/basket/{id}` - Update basket item quantity
  - DELETE `/basket/{id}` - Remove item from basket
- **Order Processing**: POST `/order` - Confirm and place an order

**Key Features:**

- In-memory basket storage (singleton service)
- CORS enabled for cross-origin requests
- OpenAPI/Swagger support in development mode
- Runs on port 8080 in containers

### Frontend (UI)

A **single-page application** built with vanilla JavaScript and served by **nginx** that provides:

- Browse available pizzas
- View pizza details, descriptions, and ingredients
- Add pizzas to basket with quantity selection
- View and modify basket contents
- Place orders

**Key Features:**

- Lightweight nginx-based static file serving
- Dynamic API URL configuration via environment variables
- Responsive design with modern CSS
- Runs on port 8080 in containers

## 🐳 Dockerfiles

Both applications use **multi-stage Docker builds** for optimized images:

### WebApi Dockerfile

```dockerfile
# Stage 1: Build - Uses SDK to compile the application
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
# - Restores NuGet packages
# - Compiles and publishes the app

# Stage 2: Runtime - Uses smaller runtime-only image
FROM mcr.microsoft.com/dotnet/aspnet:9.0
# - Copies published binaries from build stage
# - Runs as non-root user for security
# - Exposes port 8080
```

**Benefits:**

- Smaller final image (runtime vs SDK)
- Layer caching for faster rebuilds
- Secure non-root execution
- Optimized for production

### Frontend Dockerfile

```dockerfile
# Stage 1: Build - Prepares static files
FROM nginx:alpine AS build
# - Copies HTML, CSS, JS files
# - Configures nginx
# - Sets up entrypoint script

# Stage 2: Runtime - Minimal nginx image
FROM nginx:alpine
# - Copies configured files from build stage
# - Exposes port 8080
# - Dynamic API URL configuration via entrypoint
```

**Benefits:**

- Minimal Alpine-based image (~25MB)
- Runtime API URL configuration
- Custom nginx settings for SPA routing
- Fast startup and low memory footprint

## 🚀 Deployment Options

### Local Development

Run containers locally with Docker:

```powershell
# Build and run WebApi
cd src\WebApi
.\build.ps1
.\start.ps1

# Build and run Frontend
cd src\Frontend
.\build.ps1
.\start.ps1 -ApiUrl "http://localhost:8081"
```

### Azure App Service

Deploy containers to Azure App Service for a fully managed PaaS experience:

- Uses Azure Container Registry (ACR) for image storage
- Deployed via Bicep templates
- Manual container configuration in Azure Portal
- Built-in scaling and SSL

```powershell
cd eng\infrastructure
.\deploy.ps1 -DeploymentType "AppService"
```

### Azure Container Apps

Deploy to Azure Container Apps for serverless container hosting:

- Automatic scaling (including scale-to-zero)
- Built-in revision management
- Traffic splitting between revisions
- Simplified networking and ingress

Make sure that the container images are pushed to ACR before deploying.

```powershell
cd eng\infrastructure
.\deploy.ps1 -DeploymentType "ContainerApps"
```

### Azure Kubernetes Service (AKS)

Deploy to AKS for full Kubernetes orchestration:

- Complete control over container orchestration
- Kubernetes-native tools (kubectl, helm)
- Advanced deployment strategies
- Production-grade cluster management

```powershell
cd eng\infrastructure
.\deploy.ps1 -DeploymentType "AKS"

# Deploy applications to AKS
cd eng\kubernetes
.\deploy.ps1
```

## 🛠️ Prerequisites

Before starting the workshop, ensure you have:

- **Docker Desktop** or **Rancher Desktop** (with Docker CLI)
- **PowerShell Core** (PowerShell 7+)
- **Azure CLI** (for cloud deployments)
- **.NET 9 SDK** (for local .NET development)
- **Git** (to clone the repository)
- **kubectl** (for AKS deployments)
- **Visual Studio Code** (recommended)

Run the prerequisites checker:

```powershell
.\check-prerequisites.ps1
```

## 📖 Getting Started

1. **Clone the repository** (if not already done)
2. **Run the prerequisites checker** to verify your setup
3. **Start with Task 1** - [Local Docker Setup](docs/en/01-local-docker-setup.md)
4. **Progress through each task** sequentially
5. **Experiment** with different deployment options

## 🧹 Clean Up

To remove Azure resources and avoid charges:

```powershell
cd eng\infrastructure
.\destroy.ps1
```

## 📝 Learning Outcomes

By completing this workshop, you will:

- ✅ Understand Docker fundamentals and multi-stage builds
- ✅ Build and run containers locally
- ✅ Use Azure Container Registry for image management
- ✅ Deploy containers to Azure App Service
- ✅ Work with Azure Container Apps and revisions
- ✅ Deploy and manage applications on AKS
- ✅ Write infrastructure-as-code with Bicep
- ✅ Work with Kubernetes manifests and kubectl

## 📄 License

This workshop is provided for educational purposes.
