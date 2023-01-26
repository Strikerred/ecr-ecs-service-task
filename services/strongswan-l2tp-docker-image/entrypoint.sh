#!/bin/bash

# Copying secret
echo 'copying secrets'
aws s3 cp --quiet $S3_REPOPATH/$CONF-rinetd.conf /etc/rinetd.conf
aws s3 cp --quiet $S3_REPOPATH/$CONF-ipsec.secrets /etc/ipsec.secrets
aws s3 cp --quiet $S3_REPOPATH/$CONF-ipsec.conf /etc/ipsec.conf
aws s3 cp --quiet $S3_REPOPATH/$CONF-xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
aws s3 cp --quiet $S3_REPOPATH/$CONF-options.l2tpd.client /etc/ppp/options.l2tpd.client
aws s3 cp --quiet $S3_REPOPATH/$CONF-chap-secrets /etc/ppp/chap-secrets

# Setting up files
echo 'setting up files'
# When is pure L2TP, neither ipsec files nor chap-secrets are needed to be set

if [[ "${PSK}" != "noPSK" ]]; then sed -i "s/: PSK/: PSK $PSK/g" /etc/ipsec.secrets; fi
if [[ "${PSK}" != "noPSK" ]]; then sed -i "s/right=/right=$SERVER_IP/g" /etc/ipsec.conf; fi
if [[ "${PSK}" != "noPSK" ]]; then sed -i "s/*/$USERNAME * $PASSWORD */g" /etc/ppp/chap-secrets; fi
if [[ "${PSK}" == "noPSK" ]]; then 
    echo "name ${USERNAME}" >> /etc/ppp/options.l2tpd.client
    echo "password \"${PASSWORD}\"" >> /etc/ppp/options.l2tpd.client
fi
sed -i "s/lns =/lns = $SERVER_IP/g" /etc/xl2tpd/xl2tpd.conf
sed -i "s/name =/name = $USERNAME/g" /etc/xl2tpd/xl2tpd.conf

chmod 600 /etc/ipsec.secrets
chmod 600 /etc/ppp/options.l2tpd.client

exec $@