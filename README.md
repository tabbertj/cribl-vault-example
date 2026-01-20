# cribl-vault-example
Cribl Vault KMS Test

Example Repo for Setting up Cribl to use HashiCorp Vault to store the Cribl master secret

## Pre-reqs
- HashiCorp Vault installed
- jq installed
- ensure environment variables VAULT_ADDR & VAULT_TOKEN are set

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
4. Copy the Cribl KMS token from the output into the Cribl KMS settings.  After the Cribl KMS settings are saved observe the cribl.secret file is now stored in HashiCorp Vault.  In your browser navigate to the address below to access HashiCorp Vault

```
http://127.0.0.1:8200
```

The username and password are both cribl

5. In Cribl navigate to Data -> Sources and select "REST Collector" and "Add Collector"

6. On the "Add Collector" Window select "Manage as JSON" and paste the contents from the "Hashi_Vault_Token_Renew.json" file.  Update the accessor and Vault token values obtained in Step 3.  Save the collector job when finished.

7. Schedule the job to run every 10 minutes.  The Cribl KMS token in this demo will expire every 15 minutes, so the REST/API collector job will continue to renew it before it expires.  In a real world environment these times would likely be much longer.

8. Ensure you refresh the Cribl user token in the REST Collector job every 30 days to ensure it can renew the KMS token
