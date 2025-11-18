# Frontend Application

A lightweight single-page application for browsing and ordering pizzas. Built with vanilla JavaScript and served by nginx.

## Technology Stack

- **HTML5** - Semantic markup
- **CSS3** - Modern responsive design
- **Vanilla JavaScript** - No frameworks, pure JS
- **nginx** - Static file server and reverse proxy

## Application Structure

```text
Frontend/
├── index.html              # Main HTML page
├── app.js                  # JavaScript application logic
├── styles.css              # Application styles
├── nginx.conf              # nginx server configuration
├── docker-entrypoint.sh    # Container startup script
├── Dockerfile              # Container image definition
├── build.ps1               # Build Docker image script
├── deploy.ps1              # Deploy to ACR script
└── start.ps1               # Run container locally script
```

## Features

- Browse available pizzas with descriptions and ingredients
- Add pizzas to shopping basket
- Adjust quantities in basket
- Remove items from basket
- Place orders
- Responsive design for mobile and desktop

## Configuration

The frontend communicates with the backend API. The API URL is configured at runtime via environment variable:

- **Environment Variable**: `API_BASE_URL`
- **Default (local)**: `http://localhost:8081`
- **Container Port**: `8080`

## Dockerfile

Multi-stage build optimized for production:

**Stage 1 - Build:**

- Copies static files (HTML, CSS, JS)
- Configures nginx
- Sets up entrypoint script

**Stage 2 - Runtime:**

- Minimal nginx:alpine image (~25MB)
- Dynamic API URL configuration
- Non-root execution
- Exposes port 8080

## Scripts

### `build.ps1`

Builds a Docker image with automatic version management.

```powershell
.\build.ps1
```

**What it does:**

- Auto-increments version number (stored in `.version` file)
- Builds Docker image as `shop:<version>`
- Tags with both version and `latest`
- Displays build information

### `start.ps1`

Runs the container locally for testing.

```powershell
.\start.ps1 [-ApiUrl <URL>]
```

**Parameters:**

- `-ApiUrl`: Optional. Backend API URL (default: `http://localhost:8081`)

**What it does:**

- Stops any existing `shop` container
- Runs new container on port 8080
- Configures API URL
- Opens browser to <http://localhost:8080>

**Example:**

```powershell
# Start with default API URL
.\start.ps1

# Start with custom API URL
.\start.ps1 -ApiUrl "https://api-myapp.azurewebsites.net"
```

### `deploy.ps1`

Pushes the Docker image to Azure Container Registry.

```powershell
.\deploy.ps1 -AcrName <registry-name>
```

**Parameters:**

- `-AcrName`: Required. Azure Container Registry name

**What it does:**

- Reads current version from `.version` file
- Logs into ACR
- Tags image with ACR name
- Pushes to ACR

**Example:**

```powershell
.\deploy.ps1
```

## Local Development

### Without Docker

1. Use a local web server (e.g., Live Server in VS Code)
2. Update `API_BASE_URL` in `app.js` to point to your API
3. Open `index.html` in a browser

### With Docker

```powershell
# Build the image
.\build.ps1

# Start the API first (in another terminal)
cd ..\WebApi
.\build.ps1
.\start.ps1

# Start the frontend
.\start.ps1
```

Access at: <http://localhost:8080>

## nginx Configuration

Custom nginx configuration (`nginx.conf`) provides:

- Listening on port 8080
- SPA routing support (all routes serve `index.html`)
- MIME type handling
- Gzip compression
- Security headers

## Entrypoint Script

`docker-entrypoint.sh` performs runtime configuration:

1. Replaces `__API_BASE_URL__` placeholder in `app.js` with actual API URL
2. Starts nginx in foreground mode

This allows the same image to work in different environments without rebuilding.

## Environment Variables

- **`API_BASE_URL`**: Backend API URL (required)

## Ports

- **Container**: `8080`
- **Local Development**: `8080` (mapped from container)
