# WebApi Application

A REST API for managing pizza orders and shopping baskets. Built with .NET 9 and ASP.NET Core Minimal APIs.

## Technology Stack

- **.NET 9** - Latest .NET runtime
- **ASP.NET Core** - Minimal APIs
- **C#** - Programming language
- **OpenAPI/Swagger** - API documentation (dev mode)

## Application Structure

```text
WebApi/
├── Program.cs              # API entry point and endpoint definitions
├── WebApi.csproj           # .NET project file
├── appsettings.json        # Application configuration
├── appsettings.Development.json # Development settings
├── WebApi.http             # HTTP request samples
├── Dockerfile              # Container image definition
├── build.ps1               # Build Docker image script
├── deploy.ps1              # Deploy to ACR script
├── start.ps1               # Run container locally script
└── Properties/
    └── launchSettings.json # Development launch profiles
```

## API Endpoints

### Pizza Catalog

- **GET** `/pizzas` - Get all available pizzas
  - Returns: Array of pizza objects with id, name, description, and ingredients

### Basket Management

- **GET** `/basket` - Get current shopping basket
  - Returns: Basket object with items array
- **POST** `/basket` - Add item to basket
  - Body: `{ "pizzaId": 1, "quantity": 2 }`
  - Returns: Updated basket
- **PUT** `/basket/{id}` - Update item quantity
  - Body: `{ "quantity": 3 }`
  - Returns: Updated basket
- **DELETE** `/basket/{id}` - Remove item from basket
  - Returns: Updated basket

### Order Processing

- **POST** `/order` - Confirm and place order
  - Returns: Success message and clears basket

## Features

- **In-memory storage** - Basket stored in singleton service (resets on restart)
- **CORS enabled** - Allows cross-origin requests from frontend
- **OpenAPI/Swagger** - Interactive API documentation in development
- **Health checks** - Built-in endpoint monitoring

## Configuration

- **Port**: `8080` (in containers)
- **HTTPS**: Redirects to HTTPS (disabled in container)
- **CORS**: Allows all origins (configured for workshop simplicity)

## Dockerfile

Multi-stage build for optimal image size and security:

**Stage 1 - Build (SDK):**

- Uses `mcr.microsoft.com/dotnet/sdk:9.0`
- Restores NuGet packages (cached layer)
- Compiles and publishes Release build
- Output to `/app` directory

**Stage 2 - Runtime:**

- Uses `mcr.microsoft.com/dotnet/aspnet:9.0` (smaller)
- Creates non-root user for security
- Copies published binaries
- Exposes port 8080
- Runs as non-root

**Benefits:**

- Small runtime image (~200MB vs ~1GB SDK)
- Secure non-root execution
- Layer caching for fast rebuilds

## Scripts

### `build.ps1`

Builds a Docker image with automatic version management.

```powershell
.\build.ps1
```

**What it does:**

- Auto-increments version number (stored in `.version` file)
- Builds Docker image as `webapi:<version>`
- Tags with both version and `latest`
- Uses multi-stage Dockerfile for optimization
- Displays build information

### `start.ps1`

Runs the container locally for testing.

```powershell
.\start.ps1
```

**What it does:**

- Stops any existing `webapi` container
- Runs new container on port 8081 (mapped to 8080 inside)
- Displays container logs
- API accessible at <http://localhost:8081>

**Access Swagger UI**: <http://localhost:8081/openapi/v1.json>

### `deploy.ps1`

Pushes the Docker image to Azure Container Registry.

```powershell
.\deploy.ps1 -AcrName <registry-name>
```

**Parameters:**

- `-AcrName`: Required. Azure Container Registry name

**What it does:**

- Reads current version from `.version` file
- Logs into ACR using Azure CLI
- Tags image with ACR repository path
- Pushes both version tag and `latest` to ACR

**Example:**

```powershell
.\deploy.ps1
```

## Local Development

### Without Docker

```powershell
# Restore dependencies
dotnet restore

# Run the application
dotnet run
```

Access at: <https://localhost:5001> or <http://localhost:5000>

### With Docker

```powershell
# Build the image
.\build.ps1

# Run the container
.\start.ps1
```

Access at: <http://localhost:8081>

## Testing API

Use the included `WebApi.http` file with the REST Client extension in VS Code, or use curl/Postman:

```bash
# Get all pizzas
curl http://localhost:8081/pizzas

# Add to basket
curl -X POST http://localhost:8081/basket \
  -H "Content-Type: application/json" \
  -d '{"pizzaId": 1, "quantity": 2}'

# Get basket
curl http://localhost:8081/basket
```

## Data Models

### Pizza

```csharp
record Pizza(int Id, string Name, string Description, string[] Ingredients)
```

### Basket

```csharp
record Basket(List<BasketItem> Items)
record BasketItem(int Id, Pizza Pizza, int Quantity)
```

## Environment

- **Development**: Full exception details, Swagger UI enabled
- **Production**: HTTPS redirect, minimal error details

## Ports

- **Container**: `8080`
- **Local Development**: `8081` (mapped from container port 8080)
- **Direct dotnet run**: `5000` (HTTP), `5001` (HTTPS)
