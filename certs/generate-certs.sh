#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

name="llm"
hostname="${name}.local.test"

if [[ -f "${name}-cert.pem" && -f "${name}-key.pem" ]]; then
  echo "[certs] ${name}: already exists, skipping"
else
  echo "[certs] ${name}: generating self-signed leaf for ${hostname}"
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout "${name}-key.pem" -out "${name}-cert.pem" \
    -subj "/CN=${hostname}" \
    -addext "subjectAltName=DNS:${hostname},DNS:${name},DNS:localhost"
fi

echo
echo "Generated files in $(pwd):"
ls -1 *.pem
