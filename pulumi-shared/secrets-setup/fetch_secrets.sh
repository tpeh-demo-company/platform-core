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
cloudflare_account_id=$(bws secret list | jq -r '.[] | select(.key == "CLOUDFLARE_ACCOUNT_ID") | .value')
cloudflare_zone_id=$(bws secret list | jq -r '.[] | select(.key == "CLOUDFLARE_ZONE_ID") | .value')
cloudflare_api_token=$(bws secret list | jq -r '.[] | select(.key == "CLOUDFLARE_API_TOKEN") | .value')

(
    cd ..
    pulumi config set --secret auth0:clientId "$auth0_client_id"
    pulumi config set --secret auth0:clientSecret "$auth0_client_secret"
    pulumi config set --secret cloudflareAccountId "$cloudflare_account_id"
    pulumi config set --secret cloudflareZoneId "$cloudflare_zone_id"
    pulumi config set --secret cloudflare:apiToken "$cloudflare_api_token"
)

echo "Pulumi config updated."
