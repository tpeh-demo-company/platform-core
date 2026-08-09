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

auth0_client_id=$(bws secret list | jq -r '.[] | select(.key == "AUTH0_CLIENT_ID") | .value')
auth0_client_secret=$(bws secret list | jq -r '.[] | select(.key == "AUTH0_CLIENT_SECRET") | .value')

(
    cd ..
    pulumi config set --secret auth0:clientId "$auth0_client_id"
    pulumi config set --secret auth0:clientSecret "$auth0_client_secret"
)

echo "Pulumi config updated."
