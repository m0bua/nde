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
count=0
for suffix in 'd' 'local' 'l' ; do
  for service in 'adminer' 'db' 'mail' 'dns' 'a' 'd' 'm' 'v' ; do
      (( count++ )); echo "DNS.${count} = ${service}.${suffix}" >> domains.txt
  done
  for isdev in '' '-xdebug' '-xdeb' '-x' '-dev' '-d' 'xdebug' 'xdeb' 'x' 'dev' 'd'; do
    for version in '' '-prod' '-p' 'prod' 'p' '8' '83' '82' '81' '80' '7' '74' '73' '72' '71' '70' '5' '56'; do
      for exe in 'p' 'php'; do
          (( count++ )); echo "DNS.${count} = *.${exe}${version}${isdev}.${suffix}" >> domains.txt
      done
    done
  done
done

openssl req -new -nodes -newkey rsa:2048 -keyout nginx-selfsigned.key -out nginx-selfsigned.crt \
  -subj "/C=UA/ST=Ukraine/L=Kyiv/O=NDE-Certificates/CN=NDE-Selfsigned"
openssl x509 -req -sha256 -days 1024 -in nginx-selfsigned.crt -CA NdeRootCA.pem -CAkey NdeRootCA.key \
  -CAcreateserial -extfile domains.txt -out nginx-selfsigned.crt
