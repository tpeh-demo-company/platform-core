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

SECRETS_FILE="secrets.json"
if [[ ! -f "$SECRETS_FILE" ]]; then
    echo "Can't find secrets.json...exiting"
    exit 1
fi

while read -r secret; do
    name=$(echo "$secret" | jq -r '.name')
    value=$(echo "$secret" | jq -r '.value')
    note=$(echo "$secret" | jq -r '.note')

    existing_id=$(bws secret list | jq -r ".[] | select(.key == \"$name\") | .id")

    if [ -n "$existing_id" ]; then
        echo "Secret '$name' exists, updating..."
        bws secret edit "$existing_id" --value "$value" --note "$note"
    else
        echo "Secret '$name' does not exist, creating..."
        bws secret create "$name" "$value" "$BWS_PROJECT_ID" --note "$note"
    fi
done < <(jq -c '.[]' "$SECRETS_FILE")
