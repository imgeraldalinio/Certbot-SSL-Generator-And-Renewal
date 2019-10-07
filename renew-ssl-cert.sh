#!/bin/bash

echo "########START########"
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -f /etc/letsencrypt/live/README ]
then
        rm /etc/letsencrypt/live/README
fi

for i in $( ls /etc/letsencrypt/live ); do

web_service='haproxy'
config_file='/etc/letsencrypt/cli.ini'
domain=$i
combined_file="/etc/haproxy/certs/${domain}.pem"

le_path='/usr/bin/'
exp_limit=30;

if [ ! -f $config_file ]; then
        echo "[ERROR] config file does not exist: $config_file"
        exit 1;
fi

cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
key_file="/etc/letsencrypt/live/$domain/privkey.pem"

if [ ! -f $cert_file ]; then
        echo "[ERROR] certificate file not found for domain $domain."
fi

exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
datenow=$(date -d "now" +%s)
days_exp=$(echo \( $exp - $datenow \) / 86400 |bc)

echo "Checking expiration date for $domain..."

if [ "$days_exp" -gt "$exp_limit" ] ; then
        echo "The certificate is up to date, no need for renewal ($days_exp days left)."
else
        echo "The certificate for $domain is about to expire soon. Starting Let's Encrypt (HAProxy:$http_01_port) renewal script..."

        logdate="certbot-`date +\%Y\%m\%d\%H\%M\%S`.log"
        file_output=/tmp/$logdate
        $le_path/certbot certonly --renew-by-default --config $config_file --cert-name $domain -d $domain >> $file_output
        watch_error=`cat $file_output | grep "Congratulations!" | wc -l`;

        if [ $watch_error -eq 1 ]
        then
                echo "Creating $combined_file with latest certs..."
                cat /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/live/$domain/privkey.pem > $combined_file
                echo "Reloading $web_service"
                /usr/sbin/service $web_service reload
                echo "Renewal process finished for domain $domain"
        else
                echo "Failed to generate ssl certificate"
        fi

        if [ -f $file_output ]
        then
                rm $file_output
        fi

        if [ -f /etc/haproxy/certs/README.pem ]
        then
                rm /etc/haproxy/certs/README.pem
        fi

        echo "###########################################"
fi

done


