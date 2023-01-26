FROM python:3

RUN pip install awscli

RUN apt-get update
RUN apt-get install strongswan -y
RUN apt-get install xl2tpd -y
RUN apt-get install net-tools -y
RUN apt-get install iputils-ping -y
RUN apt-get install iptables -y
RUN apt-get install rinetd -y
RUN apt-get install psmisc

RUN mkdir /scripts
COPY vpn-connection /scripts

RUN chmod +x /scripts/vpn-connection

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/scripts/vpn-connection"]

ENTRYPOINT ["/entrypoint.sh"]