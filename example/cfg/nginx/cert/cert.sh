#!/bin/bash

if [[ -f "NdeRootCA.crt" ]];then
  read -p "Update RootCA? [yN]: " root
else root='y'; fi
if [[ $root =~ ^yes|y$ ]];then 
  echo
  echo "   Updating RootCA..."

  openssl req -x509 -nodes -new -sha256 -days 1024 -newkey rsa:2048 -keyout NdeRootCA.key -out NdeRootCA.pem -subj "/C=UA/CN=NDE-Root-CA"
  openssl x509 -outform pem -in NdeRootCA.pem -out NdeRootCA.crt
fi

echo
echo "   Updating Nginx Selfsigned CRT..."

openssl req -new -nodes -newkey rsa:2048 -keyout nginx-selfsigned.key -out nginx-selfsigned.crt \
  -subj "/C=UA/ST=Ukraine/L=Kyiv/O=NDE-Certificates/CN=NDE-Selfsigned"
openssl x509 -req -sha256 -days 1024 -in nginx-selfsigned.crt -CA NdeRootCA.pem -CAkey NdeRootCA.key \
  -CAcreateserial -extfile domains.txt -out nginx-selfsigned.crt
