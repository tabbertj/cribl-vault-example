#!/usr/bin/env bash

set -euo pipefail

echo "=== Vault userpass setup script starting ==="

# Ensure vault is installed
if ! command -v vault &> /dev/null; then
    echo "Error: Vault CLI not found. Please install it first."
    exit 1
fi

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

# Allow the token to renew itself
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow renewal via accessor
path "auth/token/renew-accessor" {
  capabilities = ["update"]
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
    period="15m" \
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

echo "Logging in as user 'cribl' to create periodic token for Cribl KMS..."

# Capture the token into an environment variable
CRIBL_USER_TOKEN=$(vault login -method=userpass \
    -field=token \
    username=cribl \
    password="cribl")

# Export it so subsequent vault commands use it automatically
export VAULT_TOKEN="$CRIBL_USER_TOKEN"

echo "User 'cribl' logged in successfully. Token captured."

echo "Creating Service token for Cribl"
# Create a Service token with the same access as cribl-policy
CRIBL_VAULT_KMS_TOKEN_DATA=$(vault token create \
  -role="cribl-kms-role" \
  -no-default-policy \
  -period="15m" \
  -format=json )

mapfile -t CRIBL_VAULT_CREDS < <(echo $CRIBL_VAULT_KMS_TOKEN_DATA | jq -r '.auth.client_token, .auth.accessor')

export ACCESSOR=${CRIBL_VAULT_CREDS[1]}

echo ""
echo "Service token creation successful"
echo ""
echo "Cribl KMS token:" ${CRIBL_VAULT_CREDS[0]}
echo "------------------------------------------------"
echo "Cribl KMS token accessor:" ${CRIBL_VAULT_CREDS[1]}
echo "------------------------------------------------"
echo "Cribl REST/API collector token:" $CRIBL_USER_TOKEN


echo "------------------------------------------------"
echo "Setup Complete!"
echo "1. Put the 'Cribl KMS Token' into your Cribl KMS settings."
echo "2. Put the REST/API token in the REST collector Job"
echo "3. Every 30 days update the auth token in the REST collector Job"

echo "=== Setup Complete ==="
