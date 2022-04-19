#!/bin/sh
if ! ifconfig | grep -qe "ppp0"
then
  pon dinamica debug dump logfd 2
fi