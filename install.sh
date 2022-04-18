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

echo \>Reading needed VPN Configuration Data
echo 1\)VPN host for connection
read VPN_HOST > export 
echo 2\)user for VPN Connection
read VPN_USERNAME > export 
echo 3\)password for VPN Connection
read VPN_PASSWORD > export 

echo \>Installing VPN
sudo apt update
sudo apt install pptp-linux -y

echo \>Copying VPN files
cp ./vpn/chap-secrets /etc/ppp/chap-secrets
cp ./vpn/dinamica /etc/ppp/peers/dinamica
cp ./vpn/dinamica-route /etc/ppp/ip-up.d/dinamica-route
envsubst '${VPN_USERNAME} ${VPN_PASSWORD}' < /etc/ppp/chap-secrets > out.txt && mv out.txt /etc/ppp/chap-secrets
envsubst < /etc/ppp/peers/dinamica > out.txt && mv out.txt /etc/ppp/peers/dinamica

echo \>Connecting to DINAMICA VPN
pon dinamica

echo \>Reading KeyCloak Configuration Data
echo 1\)admin user for Keycloak Interface
read KEYCLOAK_USER > export 
echo 2\)admin password for Keycloak Interface
read KEYCLOAK_PASSWORD > export 

echo KEYCLOAK_USER=$KEYCLOAK_USER>.env
echo KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD>>.env

echo \>Creating Docker Container for KeyCloak
docker-compose --env-file .env up