#!/bin/sh
set -eu

CERT_DIR="${CERT_DIR:-/etc/nginx/certs}"
KEY_FILE="${KEY_FILE:-$CERT_DIR/tls.key}"
CERT_FILE="${CERT_FILE:-$CERT_DIR/tls.crt}"

# Use localhost by default
CN="${SSL_CN:-localhost}"

mkdir -p "$CERT_DIR"

if [ -s "$KEY_FILE" ] && [ -s "$CERT_FILE" ]; then
  echo "Self-signed cert already exists: $CERT_FILE"
  exit 0
fi

echo "Generating self-signed TLS cert for CN=$CN ..."
# Create a self-signed cert + private key (unencrypted key: -nodes)
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -days "${SSL_DAYS:-365}" \
  -subj "/CN=$CN" \
  -addext "subjectAltName=DNS:$CN,DNS:localhost,IP:127.0.0.1"

chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"
echo "Generated: $CERT_FILE and $KEY_FILE"
