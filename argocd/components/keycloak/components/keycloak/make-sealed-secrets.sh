#!/usr/bin/env bash
# Generates random passwords and writes them ONLY as SealedSecrets:
#   base/sealed-secret.yaml                    -> Secret keycloak-secrets    (ns keycloak)
#   ../dex/base/sealed-keycloak-client.yaml    -> Secret dex-keycloak-client (ns dex)
# The dex client secret is sealed into both, so Keycloak and dex agree.
#
# Usage:
#   ./make-sealed-secrets.sh
#   ./make-sealed-secrets.sh --cert pub-cert.pem   (offline, e.g. on your laptop;
#                                                   get the cert with: kubeseal --fetch-cert > pub-cert.pem)
# (extra arguments are passed to kubeseal)
set -euo pipefail

cd "$(dirname "$0")"

if [[ -f base/sealed-secret.yaml ]]; then
  echo "base/sealed-secret.yaml already exists. Delete it first if you really want new passwords." >&2
  exit 1
fi

gen() { openssl rand -base64 48 | tr -d '/+=\n' | cut -c1-32; }

DB_PASSWORD="$(gen)"
ADMIN_PASSWORD="$(gen)"
DEX_CLIENT_SECRET="$(gen)"
TEST_USER_PASSWORD="$(gen)"

kubectl create secret generic keycloak-secrets -n keycloak \
  --from-literal=db-username=keycloak \
  --from-literal=db-password="$DB_PASSWORD" \
  --from-literal=admin-username=admin \
  --from-literal=admin-password="$ADMIN_PASSWORD" \
  --from-literal=dex-client-secret="$DEX_CLIENT_SECRET" \
  --from-literal=test-user-password="$TEST_USER_PASSWORD" \
  --dry-run=client -o yaml \
  | kubeseal "$@" -o yaml > base/sealed-secret.yaml

mkdir -p ../dex/base
kubectl create secret generic dex-keycloak-client -n dex \
  --from-literal=client-secret="$DEX_CLIENT_SECRET" \
  --dry-run=client -o yaml \
  | kubeseal "$@" -o yaml > ../dex/base/sealed-keycloak-client.yaml

echo "Wrote base/sealed-secret.yaml and ../dex/base/sealed-keycloak-client.yaml (safe to commit)."
echo "No plaintext was written to disk. Read passwords back from the cluster once deployed (see README.md)."
