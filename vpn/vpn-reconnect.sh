#!/bin/sh
if ! ifconfig | grep -qe "ppp0"
then
  pon dinamica
fi