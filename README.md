# Cribl/HashiCorp Vault Integration

Example Repo for Setting up Cribl to use HashiCorp Vault to store the Cribl master secret.

# CAUTION!! 

This example leverages a Vault Server running in Dev mode.  All secrets are stored in memory, if you reboot, close your terminal...etc you will lose all the secrets stored in Vault.  This is an example and should only be used for testing!! 

## Pre-reqs
- HashiCorp Vault installed
- jq installed
- ensure environment variables VAULT_ADDR & VAULT_TOKEN are set

## Getting Started


1. Start a Vault Dev Server
```
vault server -dev -dev-root-token-id=root
```
2. On a new terminal set the Vault environment Variables
```
export VAULT_ADDR='http://127.0.0.1:8200'
```
```
export VAULT_TOKEN=root
```
3. Clone the repository
```
git clone https://github.com/tabbertj/cribl-vault-example.git
```

4. Enter the directory
```
cd cribl-vault-example
```

5. Run the script
```
./vault-setup.sh
```
6. Copy the Cribl KMS token from the output into the Cribl KMS settings.  After the Cribl KMS settings are saved observe the cribl.secret file is now stored in HashiCorp Vault.  In your browser navigate to the address below to access HashiCorp Vault

mount = secret
<br>
path = cribl

```
http://127.0.0.1:8200
```

The username and password are both cribl

7. In Cribl navigate to Data -> Sources and select "REST Collector" and "Add Collector"

8. On the "Add Collector" Window select "Configure as JSON" and paste the contents from the "Hashi_Vault_Token_Renew.json" file.  Update the accessor and Vault token values obtained in Step 3.  Save the collector job when finished.

9. Schedule the job to run every 10 minutes.  The Cribl KMS token in this demo will expire every 15 minutes, so the REST/API collector job will continue to renew it before it expires.  In a real world environment these times would likely be much longer.

10. Ensure you refresh the Cribl user token in the REST Collector job every 30 days to ensure it can renew the KMS token

11. Use the vault token lookup command to validate the Vault KMS Token is being renewed.  You should see the TTL being refreshed as the job runs

```
vault token lookup (Paste KMS Token value from Step 3)
```

OR

```
vault token lookup -accessor (Paste accessor value from Step 3)
```
