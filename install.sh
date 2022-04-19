#!/usr/bin/env bash
# ENV Variables
# VPN_HOST (VPN host for connection)
# VPN_USERNAME (user for VPN Connection)
# VPN_PASSWORD (password for VPN Connection)
# KEYCLOAK_USER (admin user for Keycloak Interface)
# KEYCLOAK_PASSWORD (admin password for Keycloak Interface)

# echo \>Switching to user Home folder
# cd ~

# echo \>Cloning auth-server git repository
# git clone https://github.com/diegoarmiliato/auth-server.git

# cd ~/auth-server
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
if grep -qe "-A ufw-before-input -p 47 -j ACCEPT" /etc/ufw/before.rules;
then
  echo rules already added
else
  sed -i "s:# don't delete the 'COMMIT': # allow PPTP VPN\n-A ufw-before-input -p 47 -j ACCEPT\n-A ufw-before-output -p 47 -j ACCEPT\n\n# don't delete the 'COMMIT':" /etc/ufw/before.rules
  echo rules added
fi
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
echo \>UFW Firewall Reload

echo ""
echo =========================================================
echo \>Creating VPN Reconnection CRON Job
echo =========================================================
if crontab -l | grep -e "vpn-reconnect";
then
  echo job already configured
else
  echo "SHELL=/bin/sh" | crontab -
  (crontab -l 2>/dev/null || true; echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin") | crontab -
  (crontab -l 2>/dev/null || true; echo "* * * * * /root/auth-server/vpn/vpn-reconnect.sh") | crontab -
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
echo \>Creating Docker Container for KeyCloak
echo =========================================================
docker-compose --env-file .env up --detach