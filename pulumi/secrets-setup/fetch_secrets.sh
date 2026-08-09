#!/usr/bin/env bash
set -eou pipefail

ENV_FILE="../.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Can't find env file...exiting"
    exit 1
fi

set -o allexport
source "$ENV_FILE"
set +o allexport

sops_age_private_key=$(bws secret list | jq -r '.[] | select(.key == "SOPS_AGE_PRIVATE_KEY") | .value')

(
    cd ..
    pulumi config set --secret sops:agePrivateKey "$sops_age_private_key"
)

echo "Pulumi config updated."
