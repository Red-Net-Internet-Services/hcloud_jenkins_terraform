#!/bin/bash

# Exit on error
set -e

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
}

log "Installing certbot package"

# Install Certbot and get an SSL certificate
apt-get update
apt-get install -y certbot python3-certbot-nginx

log "Requesting certificate..."
certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m $ADMIN_EMAIL --redirect

# Restart Nginx to apply changes
systemctl restart nginx