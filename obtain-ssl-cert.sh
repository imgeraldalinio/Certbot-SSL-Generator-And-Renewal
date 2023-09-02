#!/bin/bash

# Check for domain names as arguments
if [ $# -lt 1 ]; then
    echo "At least one or more domain names are required (e.g., example.com www.example.com)"
    exit 1
fi

# Concatenate the requested domains
DOMAINS=("$@")

# Extract root domain (e.g., example.com) from the list
root_domain=""
for domain in "${DOMAINS[@]}"; do
    if [[ $domain =~ ([a-zA-Z0-9-]+\.[a-zA-Z]{2,24}) ]]; then
        root_domain="${BASH_REMATCH[1]}"
        break
    fi
done

# Prepare certbot command
certbot_command="certbot certonly --config /etc/letsencrypt/cli.ini -d $root_domain"

# Add additional domains to the certbot command
for domain in "${DOMAINS[@]}"; do
    certbot_command+=" -d $domain"
done

# Execute the certbot command
echo "Running Certbot command: $certbot_command"
eval "$certbot_command"

# Check if SSL certificate was obtained successfully
if [ ! -d "/etc/letsencrypt/live/$root_domain" ]; then
    echo "Failed to obtain SSL certificate!"
    exit 1
fi

# Copy Let's Encrypt certificate to HAProxy certs folder
cert_path="/etc/letsencrypt/live/$root_domain"
cat "$cert_path/fullchain.pem" "$cert_path/privkey.pem" > "/etc/haproxy/certs/$root_domain.pem"
chmod 600 "/etc/haproxy/certs/$root_domain.pem"

# Reload HAProxy
/etc/init.d/haproxy reload

echo "SSL certificate obtained and applied successfully for $root_domain."

exit 0
