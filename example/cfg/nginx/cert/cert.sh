#!/bin/bash

if [[ -f "NdeRootCA.crt" ]];then
  read -p "Update RootCA? [yN]: " root
else root='y'; fi
if [[ $root =~ ^yes|y$ ]];then

  echo; echo "   Updating RootCA..."

  openssl req -x509 -nodes -new -sha256 -days 1024 -newkey rsa:2048 -keyout NdeRootCA.key \
    -out NdeRootCA.pem -subj "/C=UA/CN=NDE-Root-CA"
  openssl x509 -outform pem -in NdeRootCA.pem -out NdeRootCA.crt
fi

echo; echo "   Updating Nginx Selfsigned CRT..."

echo 'authorityKeyIdentifier=keyid,issuer' > domains.txt
echo 'basicConstraints=CA:FALSE' >> domains.txt
echo 'keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment' >> domains.txt
echo 'subjectAltName = @alt_names' >> domains.txt
echo '[alt_names]' >> domains.txt
i=0
for d in 'v' 'a' 'd' 'm' 'g' 'adminer' 'db' 'mail' 'dns' 'gulp'; do
  (( i++ )); echo "DNS.${i} = ${d}.d" >> domains.txt
done
for v in '' '5' '7' '8' '56' '70' '71' '72' '73' '74' '80' '81'; do for d in '' 'd'; do
  (( i++ )); echo "DNS.${i} = *.php${v}${d}.d" >> domains.txt
done; done

openssl req -new -nodes -newkey rsa:2048 -keyout nginx-selfsigned.key -out nginx-selfsigned.crt \
  -subj "/C=UA/ST=Ukraine/L=Kyiv/O=NDE-Certificates/CN=NDE-Selfsigned"
openssl x509 -req -sha256 -days 1024 -in nginx-selfsigned.crt -CA NdeRootCA.pem -CAkey NdeRootCA.key \
  -CAcreateserial -extfile domains.txt -out nginx-selfsigned.crt
