#!/bin/zsh
CONFIG="""
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost"""

# Echo out the config which will give us a localhost SAN
echo $CONFIG > rustica.ext

# Generate CA Key and Cert
openssl ecparam -genkey -name prime256v1 -noout -out ca.key
openssl req -x509 -new -key ca.key -nodes -days 3650 -out ca.pem -subj '/CN=RusticaRootCA'

# Generate Client CA Key and Cert
openssl ecparam -genkey -name prime256v1 -noout -out client_ca.key
openssl req -new -key client_ca.key -x509 -nodes -days 3650 -out client_ca.pem -subj '/CN=RusticaClientRootCA'

# Generate Server Key
openssl ecparam -genkey -name prime256v1 -noout -out private.pem

# Convert server key to pkcs8
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in private.pem -out rusticaserver.key
rm private.pem

# Create certificate signing request
openssl req -new -key rusticaserver.key -out rusticaserver.csr -subj '/CN=RusticaServer/O=Rustica/C=CA'

# Use the CA to generate the cert
openssl x509 -req -in rusticaserver.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out rusticaserver.pem -days 825 -sha256 -extfile rustica.ext

# Clean up
rm *.ext
rm *.srl
rm *.csr
