#!/bin/bash

# Define your configuration variables
DOMAINS=("linuxbeast.com")
WEB_SERVICE="haproxy"
CONFIG_FILE="/etc/letsencrypt/cli.ini"
EXP_LIMIT=5 # Auto renew in 5 days.
LE_PATH="/usr/bin/"

# Function to renew a domain certificate
renew_certificate() {
  local domain="$1"
  local cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
  local key_file="/etc/letsencrypt/live/$domain/privkey.pem"
  local combined_file="/etc/haproxy/certs/${domain}.pem"

  if [ ! -f "$cert_file" ]; then
    echo "[ERROR] Certificate file not found for domain $domain."
    return
  fi

  local exp=$(date -d "$(openssl x509 -in "$cert_file" -text -noout | grep 'Not After' | cut -c 25-)" +%s)
  local datenow=$(date -d "now" +%s)
  local days_exp=$(( (exp - datenow) / 86400 ))

  echo "Checking expiration date for $domain..."

  if [ "$days_exp" -gt "$EXP_LIMIT" ]; then
    echo "The certificate is up to date, no need for renewal ($days_exp days left)."
  else
    echo "The certificate for $domain is about to expire soon. Starting Let's Encrypt renewal script..."
    certbot certonly --agree-tos --standalone --config "$CONFIG_FILE" -d "$domain,www.$domain"

    echo "Creating $combined_file with the latest certs..."
    sudo bash -c "cat \"$cert_file\" \"$key_file\" > \"$combined_file\""

    echo "Reloading $WEB_SERVICE"
    /usr/sbin/service "$WEB_SERVICE" reload
    echo "Renewal process finished for domain $domain"
  fi
}

# Loop through the domains and renew certificates
for domain in "${DOMAINS[@]}"; do
  renew_certificate "$domain"
done

# To set up auto-renewal for your Let's Encrypt certificates using cron, you can follow these steps:
# Open the cron configuration file for editing. You can typically do this by running:
# crontab -e
# Add an entry to your cron file that specifies when and how often you want to run the certificate renewal script. 
# For example, to run the script every day at 2:00 AM, you can add the following line:
# 0 2 * * * /bin/bash /home/ubuntu/ssl/renewal.sh /var/log/letsencrypt-renew.log 2>&1
