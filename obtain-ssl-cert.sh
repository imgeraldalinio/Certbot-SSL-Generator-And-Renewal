#!/bin/bash

# checking domain name
if [ $# -lt 1 ]
then
    echo "At least one or more domain name is required: (e.g example.com www.example.com)"
    exit 1
fi

# Concat the requested domains
DOMAINS=""
for i in "$@"
do
    DOMAINS+=" -d $i"
done

# filter domain name
domain_name=$(printf "$DOMAINS" | grep -oE '[a-z0-9][a-z0-9-]{0,61}[a-z0-9](\w{2,}\.\w{2,3}\.\w{2,3}|\w{1,}\.\w{2,24})$')

# dns challenge
# certbot certonly --config /etc/letsencrypt/cli.ini  --manual --preferred-challenges dns $DOMAINS --cert-name $domain_name

matched_root_domain=`echo $DOMAINS | grep -F -- "-d $domain_name" | wc -l`
if [ $matched_root_domain -eq 1 ]
then
        # remove root domain from $DOMAINS
        remove_root_domain=`echo $DOMAINS | sed 's/-d '$domain_name'//g'`

        # http-01 challenge
        echo "Certbot command 1"
        certbot certonly --config /etc/letsencrypt/cli.ini -d $domain_name $remove_root_domain --cert-name $domain_name
else
        echo "Certbot command 2"
        certbot certonly --config /etc/letsencrypt/cli.ini -d $domain_name $DOMAINS --cert-name $domain_name
fi


if [ ! -d "/etc/letsencrypt/live/$domain_name" ]
then
        echo "Failed to obtain SSL certificate!"
else
        # Remove readme file if exists to avoid error
        if [ -f /etc/letsencrypt/live/README ]
        then
                rm /etc/letsencrypt/live/README
        fi
        # Copy letsencrypt certificate and place to haproxy certs folder
        cat /etc/letsencrypt/live/$domain_name/{fullchain.pem,privkey.pem} > /etc/haproxy/certs/$domain_name.pem
        chmod 600 /etc/haproxy/certs/$domain_name.pem

        sleep 1
        # reload haproxy
        /etc/init.d/haproxy reload
fi

exit 0
