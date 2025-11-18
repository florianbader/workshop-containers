# =============================================================================
# STAGE 1: BUILD (prepare static files)
# =============================================================================
# Use nginx alpine image as base
FROM nginx:alpine AS build

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy our static files to nginx html directory
COPY src/Frontend/*.html /usr/share/nginx/html/
COPY src/Frontend/*.css /usr/share/nginx/html/
COPY src/Frontend/*.js /usr/share/nginx/html/

# Copy custom nginx configuration
COPY src/Frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY src/Frontend/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# =============================================================================
# STAGE 2: RUNTIME
# =============================================================================
FROM nginx:alpine

# Copy everything from build stage
COPY --from=build /usr/share/nginx/html /usr/share/nginx/html
COPY --from=build /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /docker-entrypoint.sh /docker-entrypoint.sh

# Expose port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
