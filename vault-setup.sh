#!/usr/bin/env bash

set -euo pipefail

echo "=== Vault userpass setup script starting ==="

#
# Check environment variables
#
if [[ -z "${VAULT_ADDR:-}" ]]; then
  echo "ERROR: VAULT_ADDR is not set"
  exit 1
fi

if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "ERROR: VAULT_TOKEN is not set"
  exit 1
fi

echo "Using Vault at: $VAULT_ADDR"
echo "Vault token is set"

#
# Check if userpass auth is already enabled
#
echo "Checking if userpass auth method is enabled..."
if vault auth list -format=json | jq -e '."userpass/"' >/dev/null 2>&1; then
  echo "userpass auth is already enabled — moving on"
else
  echo "Enabling userpass auth method..."
  vault auth enable userpass
  echo "userpass auth enabled"
fi

#
# Create or update the policy
#
echo "Creating/updating policy 'cribl-policy'..."
cat <<EOF | vault policy write cribl-policy -
path "secret/cribl" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/cribl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# KV v2 data endpoint
path "secret/data/cribl" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow Cribl user to create initial authentication token
path "auth/token/create/cribl-kms-role" {
  capabilities = ["create", "update", "sudo"]
}

# Allow Cribl to create child tokens
path "auth/token/create" {
  capabilities = ["update"]
}

# Allow Cribl to look up its own token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "secret/*" {
  capabilities = ["list"]
}
EOF
echo "Policy 'cribl-policy' applied"

#
# Create or update the user
#
echo "Creating/updating user 'cribl'..."
vault write auth/userpass/users/cribl \
  password="cribl" \
  policies="cribl-policy"

echo "User 'cribl' created/updated successfully"

#
# Create Token Role
#
vault write auth/token/roles/cribl-kms-role \
    allowed_policies="cribl-policy" \
    disallowed_policies="default" \
    token_no_default_policy=true \
    orphan=true \
    period="5m" \
    renewable=true

# Write a test secret
#
echo "Writing test secret to secret/cribl..."
vault kv put secret/cribl test="test"
echo "Test secret written to secret/cribl"
echo "------------------------"

#
# Create Service Token
#

unset VAULT_TOKEN

# Create User Token
echo "Logging in as user 'cribl' to retrieve token..."
vault login -method=userpass \
    username=cribl \
    password="cribl" 

echo "Creating Service token for Cribl"
# Create a Service token with the same access as cribl-policy
CRIBL_VAULT_KMS_TOKEN_DATA=$(vault token create \
  -role="cribl-kms-role" \
  -no-default-policy \
  -period="5m" \
  -format=json )

mapfile -t CRIBL_VAULT_CREDS < <(echo $CRIBL_VAULT_KMS_TOKEN_DATA | jq -r '.auth.client_token, .auth.accessor')

echo ""
echo "Service token creation successful"
echo ""
echo "token:" ${CRIBL_VAULT_CREDS[0]}
echo "accessor:" ${CRIBL_VAULT_CREDS[1]}
echo ""

echo "=== Setup Complete ==="
