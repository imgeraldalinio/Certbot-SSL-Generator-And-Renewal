# Certificate Renewal Script Using Certbot

![Certbot Logo](https://raw.githubusercontent.com/certbot/certbot/main/certbot-distribution/logos/certbot-logo-72p.png)

This project includes a Bash script for automating the renewal of SSL/TLS certificates using [Certbot](https://certbot.eff.org/). Certbot is a free, open-source software tool that simplifies the process of obtaining and renewing SSL/TLS certificates for your web server.

## Overview

The script is designed to automate the renewal of SSL/TLS certificates for specified domains. It checks the expiration date of each certificate and renews it if it's about to expire soon. The renewed certificates are then combined into a single PEM file for use with your web server (e.g., HAProxy).

## Prerequisites

Before using this script, ensure that you have the following prerequisites:

- [Certbot](https://certbot.eff.org/) is installed on your system.
- Properly configured SSL/TLS certificates for your domains.

## Usage

1. Clone this repository or copy the script (`renew_certificates.sh`) to your server.

2. Make the script executable:

   ```bash
   chmod +x renew_certificates.sh
   ```
3. Modify the script to suit your configuration:
   - Update the DOMAINS array with the domains for which you want to renew certificates.
   - Set WEB_SERVICE to the name of your web server service (e.g., haproxy).
   - Adjust the CONFIG_FILE, LE_PATH, and EXP_LIMIT variables as needed.
  
4. Run the script to check and renew certificates:
  ```
  sudo ./renew_certificates.sh
  ```
  The script will check each domain's certificate and renew it if necessary. The renewed certificates will be combined into PEM files.

5. Schedule the script to run periodically using a tool like cron to ensure automatic renewal.

## Script Internals

- The script calculates the remaining days to certificate expiration and checks if it's within the specified EXP_LIMIT.
- If renewal is required, it uses Certbot to renew the certificate and updates the combined certificate file.
- Finally, it reloads the specified web service to apply the new certificate.

## Troubleshooting

- If you encounter any issues with certificate renewal, check the Certbot logs for more details.

## Contributing
Contributions to this project are welcome! If you have suggestions for improvements or encounter issues, please open an issue or submit a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](https://chat.openai.com/LICENSE) file for details.
   
