#!/bin/sh
# Docker entrypoint script for Frontend container
# This script substitutes environment variables in the JavaScript file before starting nginx

# Set default value if not provided
APP_API_BASE_URL=${APP_API_BASE_URL:-http://localhost:5200}

echo "Configuring Frontend with API Base URL: $APP_API_BASE_URL"

# Substitute the placeholder in app.js with the actual environment variable value
sed -i "s|__API_BASE_URL__|$APP_API_BASE_URL|g" /usr/share/nginx/html/app.js

echo "Configuration complete. Starting nginx..."

# Start nginx in the foreground
exec nginx -g "daemon off;"
