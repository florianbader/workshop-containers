# =============================================================================
# STAGE 1: BUILD
# =============================================================================
# Use the official .NET SDK image to compile and build our application
# The SDK includes everything needed to build .NET apps (compilers, tools, etc.)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Set the working directory inside the container
# Think of this as doing 'cd /source' - all commands run from here
WORKDIR /source

# Copy only the project file first (before copying all code)
# Why? Docker caches layers - if the .csproj hasn't changed, 
# the restore step won't run again, saving time on rebuilds
COPY src/WebApi/*.csproj .

# Restore NuGet packages (download dependencies)
# This step is cached separately from the build step
RUN dotnet restore --verbosity minimal

# Now copy all remaining source code files
# We do this AFTER restore to maximize Docker cache efficiency
COPY src/WebApi/. .

# Build the app in Release mode (optimized) and publish to /app
# --no-restore: Skip restore since we already did it above
# -o /app: Output the published files to /app directory
RUN dotnet publish -c Release -o /app --no-restore

# =============================================================================
# STAGE 2: RUNTIME
# =============================================================================
# Use the smaller ASP.NET runtime-only image (no SDK bloat)
FROM mcr.microsoft.com/dotnet/aspnet:9.0

# Create a non-root user for better security
# Running as root in containers is a security risk
RUN useradd -m -s /bin/bash appuser

# Set working directory for the runtime container
WORKDIR /app

# Copy the published app from the build stage
# --from=build: Get files from the previous stage named "build"
COPY --from=build /app ./

# Change ownership of app files to our non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080 (ASP.NET Core default in .NET 9)
# This is documentation only - doesn't actually publish the port
# Containers can still map ports at runtime
EXPOSE 8080

# Define the command to run when the container starts
ENTRYPOINT ["dotnet", "WebApi.dll"]