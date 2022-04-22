#!/usr/bin/env bash
# ENV Variables
# VPN_HOST (VPN host for connection)
# VPN_USERNAME (user for VPN Connection)
# VPN_PASSWORD (password for VPN Connection)
# KEYCLOAK_USER (admin user for Keycloak Interface)
# KEYCLOAK_PASSWORD (admin password for Keycloak Interface)
echo ""
echo =========================================================
echo \>Reading needed VPN Configuration Data
echo =========================================================
echo 1\)VPN host for connection
read VPN_HOST && export VPN_HOST=$VPN_HOST
echo 2\)user for VPN Connection
read VPN_USERNAME && export VPN_USERNAME=$VPN_USERNAME
echo 3\)password for VPN Connection
read VPN_PASSWORD && export VPN_PASSWORD=$VPN_PASSWORD

echo ""
echo =========================================================
echo \>Installing VPN and Net Tools
echo =========================================================
sudo apt update
sudo apt install pptp-linux net-tools -y

echo ""
echo =========================================================
echo \>Copying VPN files
echo =========================================================
cp ./vpn/chap-secrets /etc/ppp/chap-secrets
cp ./vpn/dinamica /etc/ppp/peers/dinamica
cp ./vpn/dinamica-route /etc/ppp/ip-up.d/dinamica-route
chmod +x /etc/ppp/ip-up.d/dinamica-route
envsubst < /etc/ppp/chap-secrets > out.txt && mv out.txt /etc/ppp/chap-secrets
envsubst < /etc/ppp/peers/dinamica > out.txt && mv out.txt /etc/ppp/peers/dinamica

echo ""
echo =========================================================
echo \>Adding Firewall Rules to UFW
echo =========================================================
ufw allow 1723
echo \>UFW Firewall Reload
ufw reload

echo ""
echo =========================================================
echo \>Setting VPN to Autoconnect on Reboot
echo =========================================================
if grep -qe "auto tunnel" /etc/network/interfaces;
then
  echo already set autoconnect on reboot
else
  echo "auto tunnel" >> /etc/network/interfaces
  echo "iface tunnel inet ppp" >> /etc/network/interfaces
  echo "  provider dinamica" >> /etc/network/interfaces
  echo rules added
fi

echo ""
echo =========================================================
echo \>Creating VPN Reconnection CRON Job
echo =========================================================
cp ./vpn/vpn-reconnect.sh ~/vpn-reconnect.sh
chmod +x ~/vpn-reconnect.sh
if crontab -l | grep -e "vpn-reconnect";
then
  echo job already configured
else
  echo "SHELL=/bin/sh" | crontab -
  (crontab -l 2>/dev/null || true; echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin") | crontab -
  (crontab -l 2>/dev/null || true; echo "* * * * * /root/vpn-reconnect.sh") | crontab -
  echo job configured
fi

echo ""
echo =========================================================
echo \>Connecting to DINAMICA VPN
echo =========================================================
pon dinamica debug dump logfd 2

echo ""
echo =========================================================
echo \>Reading KeyCloak Configuration Data
echo =========================================================
echo 1\)admin user for Keycloak Interface
read KEYCLOAK_USER > export 
echo 2\)admin password for Keycloak Interface
read KEYCLOAK_PASSWORD > export 

echo KEYCLOAK_USER=$KEYCLOAK_USER>.env
echo KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD>>.env

echo ""
echo =========================================================
echo \>Making first Certificate Acquisition with Mock Nginx
echo =========================================================
cp ./nginx/first.conf ./nginx/default.conf
docker-compose up -d nginx 
docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d auth.dinamicacp.com
docker-compose down
cp ./nginx/final.conf ./nginx/default.conf

echo ""
echo =========================================================
echo \>Creating Certificate Renewall CRON Job
echo =========================================================
chmod +x ./vpn/vpn-reconnect.sh
if crontab -l | grep -e "certbot";
then
  echo job already configured
else
  (crontab -l 2>/dev/null || true; echo "0 1 * * * docker-compose -f /root/auth-server/docker-compose.yml run --rm certbot renew >> /var/log/cert-renewall.log 2>&1") | crontab -
  echo job configured
fi

echo ""
echo =========================================================
echo \>Creating Docker Container for KeyCloak
echo =========================================================
docker-compose --env-file .env up --detach