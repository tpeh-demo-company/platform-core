## Generate the age keypair

```bash
age-keygen -o ~/.config/sops/age/platform-services.txt
```

This writes the private key file (used below) and prints the public key — put the public key in `platform-services/.sops.yaml`'s `age:` field so SOPS encrypts secrets to it.

## Get the key into Bitwarden Secrets Manager

Don't hand-type the age private key into `secrets.json` — it's multi-line (comments + the `AGE-SECRET-KEY-...` line) and manually escaping newlines in a JSON string is error-prone. Build the file with `jq --rawfile` instead, which handles escaping for you:

```bash
jq -n --rawfile key ~/.config/sops/age/platform-services.txt '[{
  "name": "SOPS_AGE_PRIVATE_KEY",
  "value": $key,
  "note": "SOPS age private key used to decrypt platform-services secrets"
}]' > secrets.json
```

Then run `./inject_secrets.sh` to push it into Bitwarden Secrets Manager.
