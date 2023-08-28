#!/bin/bash

# Exit on error
set -e

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
}

log "Starting Jenkins installation..."
log "Installing dependencies..."
# Update repositories and install dependencies
sudo apt update
sudo apt install openjdk-17-jre wget gnupg software-properties-common -y

# Add Jenkins repository key
log "Adding Jenkins repository key..."

# Add Jenkins repository and install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y

log "Starting Jenkins..."
systemctl start jenkins
systemctl enable jenkins

log "Installing Nginx..."
# Install nginx as a reverse proxy for Jenkins
apt-get install -y nginx
cp /tmp/jenkins_nginx.conf /etc/nginx/sites-available/jenkins

log "Replacing domain name"
# Replace the placeholder in the nginx configuration with the actual domain name
sed -i "s/DOMAIN_NAME_PLACEHOLDER/${DOMAIN_NAME}/g" /etc/nginx/sites-available/jenkins

ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
systemctl restart nginx
