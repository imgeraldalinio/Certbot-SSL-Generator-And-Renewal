#!/bin/bash

echo "########START########"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Remove the README file if it exists
if [ -f /etc/letsencrypt/live/README ]; then
  rm /etc/letsencrypt/live/README
fi

# Define common configuration variables
web_service='haproxy'
config_file='/etc/letsencrypt/cli.ini'
le_path='/usr/bin/'
exp_limit=30

# Function to renew a domain certificate
renew_certificate() {
  local domain="$1"
  local cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
  local key_file="/etc/letsencrypt/live/$domain/privkey.pem"
  local combined_file="/etc/haproxy/certs/${domain}.pem"

  # Check if the configuration file exists
  if [ ! -f "$config_file" ]; then
    echo "[ERROR] Config file does not exist: $config_file"
    exit 1
  fi

  # Check if the certificate file exists
  if [ ! -f "$cert_file" ]; then
    echo "[ERROR] Certificate file not found for domain $domain."
    return
  fi

  # Calculate the expiration date in days
  local exp=$(date -d "$(openssl x509 -in "$cert_file" -text -noout | grep 'Not After' | cut -c 25-)" +%s)
  local datenow=$(date -d "now" +%s)
  local days_exp=$(( (exp - datenow) / 86400 ))

  echo "Checking expiration date for $domain..."

  if [ "$days_exp" -gt "$exp_limit" ]; then
    echo "The certificate is up to date, no need for renewal ($days_exp days left)."
  else
    echo "The certificate for $domain is about to expire soon. Starting Let's Encrypt renewal script..."

    local logdate="certbot-$(date +%Y%m%d%H%M%S).log"
    local file_output="/tmp/$logdate"
    
    # Renew the certificate
    $le_path/certbot certonly --renew-by-default --config "$config_file" --cert-name "$domain" -d "$domain" >> "$file_output"
    local watch_error=$(cat "$file_output" | grep "Congratulations!" | wc -l)

    if [ $watch_error -eq 1 ]; then
      echo "Creating $combined_file with latest certs..."
      cat "$cert_file" "$key_file" > "$combined_file"
      echo "Reloading $web_service"
      /usr/sbin/service "$web_service" reload
      echo "Renewal process finished for domain $domain"
    else
      echo "Failed to generate SSL certificate"
    fi

    # Remove the temporary log file
    if [ -f "$file_output" ]; then
      rm "$file_output"
    fi
  fi
}

# Loop through the domains and renew certificates
for domain in /etc/letsencrypt/live/*; do
  if [ -d "$domain" ]; then
    renew_certificate "$(basename "$domain")"
  fi
done

echo "########END########"
