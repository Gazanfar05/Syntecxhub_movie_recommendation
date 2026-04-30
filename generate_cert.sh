#!/bin/bash

# Generate self-signed certificate for localhost

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CERT_DIR="$SCRIPT_DIR/certs"

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Check if certificates already exist
if [ -f "$CERT_DIR/server.crt" ] && [ -f "$CERT_DIR/server.key" ]; then
    echo "✓ Certificates already exist at $CERT_DIR"
    echo "  - server.crt"
    echo "  - server.key"
    exit 0
fi

echo "🔐 Generating self-signed SSL certificate for localhost..."

# Generate private key (2048-bit RSA)
openssl genrsa -out "$CERT_DIR/server.key" 2048 2>/dev/null

# Generate certificate valid for 365 days
openssl req -new -x509 -key "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.crt" \
    -days 365 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:127.0.0.1" \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ SSL certificate generated successfully!"
    echo ""
    echo "Certificate details:"
    echo "  Location: $CERT_DIR/"
    echo "  - Private Key: server.key"
    echo "  - Certificate: server.crt"
    echo ""
    echo "⚠️  Note: This is a self-signed certificate for local development only."
    echo "   Your browser will show a security warning - this is expected."
else
    echo "✗ Failed to generate certificate"
    exit 1
fi
