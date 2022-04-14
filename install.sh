#!/usr/bin/env bash
# ENV Variables
# VPN_HOST (VPN host for connection)
# VPN_USERNAME (user for VPN Connection)
# VPN_PASSWORD (password for VPN Connection)
# KEYCLOAK_PASSWORD (admin password for Keycloak Interface)
# KEYCLOAK_USER (admin user for Keycloak Interface)
# KEYCLOAK_PASSWORD (admin password for Keycloak Interface)

#mkdir ./auth-server
#cd ./auth-server
#git clone xpto

cp ./vpn/chap-secrets /etc/ppp/chap-secrets
cp ./vpn/dinamica /etc/ppp/peers/dinamica
cp ./vpn/dinamica-route /etc/ip-up.d/dinamica-route

pon dinamica

echo KEYCLOAK_USER=$KEYCLOAK_USER>.env
echo KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD>>.env

docker-compose --env-file .env up

