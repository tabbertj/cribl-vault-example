# cribl-vault-example
Cribl Vault KMS Test

Example Repo for Setting up Cribl to use HashiCorp Vault to store the Cribl master secret

## Pre-reqs
- HashiCorp Vault installed
- jq installed
- ensure environment variables VAULD_ADDR & VAULT_TOKEN are set

## Getting Started

1. Start a Vault Dev Server
```
vault server -dev -dev-root-token-id=root
```
2. Set environment Variables
```
export VAULT_ADDR='http://127.0.0.1:8200'
```
```
export VAULT_TOKEN=root
```
3. Run the script
```
./vault-setup.sh
```
4. Copy the token from the output into the Cribl KMS settings.  After the Cribl KMS settings are saved observe the cribl.secret file is now stored in HashiCorp Vault

```
http://127.0.0.1:8200
```

The username and password are both cribl

5. Use external tooling to renew the token on a schedule via the accessor value.  This script uses a 10min token expiry for the purpose of demonstration.  In a real deployment the token would have a longer TTL 
