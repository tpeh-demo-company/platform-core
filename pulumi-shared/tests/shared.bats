#!/usr/bin/env bats
# Shared infrastructure validation tests.
# Prerequisites: AUTH0_DOMAIN, AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET,
#                CF_API_TOKEN, CF_ACCOUNT_ID, CF_ZONE_ID, CLUSTERS, DOMAIN exported by CI

CF_API="https://api.cloudflare.com/client/v4"

setup_file() {
  # Exchange client credentials for a Management API token once per run
  response=$(curl -sf \
    -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
    -H "Content-Type: application/json" \
    -d "{
      \"grant_type\": \"client_credentials\",
      \"client_id\": \"${AUTH0_CLIENT_ID}\",
      \"client_secret\": \"${AUTH0_CLIENT_SECRET}\",
      \"audience\": \"https://${AUTH0_DOMAIN}/api/v2/\"
    }")
  export AUTH0_MGMT_TOKEN=$(echo "$response" | jq -r '.access_token')
}

# ── Auth0 ─────────────────────────────────────────────────────────────────────

@test "auth0 kubernetes client exists for each cluster" {
  for cluster in $CLUSTERS; do
    run curl -sf \
      -H "Authorization: Bearer ${AUTH0_MGMT_TOKEN}" \
      "https://${AUTH0_DOMAIN}/api/v2/clients?fields=name&name=kubernetes-${cluster}"
    [ "$status" -eq 0 ]
    count=$(echo "$output" | jq 'length')
    [ "$count" -gt 0 ]
  done
}

@test "auth0 platform roles exist" {
  run curl -sf \
    -H "Authorization: Bearer ${AUTH0_MGMT_TOKEN}" \
    "https://${AUTH0_DOMAIN}/api/v2/roles"
  [ "$status" -eq 0 ]
  names=$(echo "$output" | jq -r '.[].name')
  echo "$names" | grep -q "platform-admin"
  echo "$names" | grep -q "platform-user"
}

# ── Cloudflare ────────────────────────────────────────────────────────────────

@test "cloudflare tunnel exists for each cluster" {
  for cluster in $CLUSTERS; do
    run curl -sf \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      "${CF_API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?name=${cluster}&is_deleted=false"
    [ "$status" -eq 0 ]
    count=$(echo "$output" | jq '.result | length')
    [ "$count" -gt 0 ]
  done
}

@test "cloudflare wildcard cname exists for each cluster" {
  for cluster in $CLUSTERS; do
    run curl -sf \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      "${CF_API}/zones/${CF_ZONE_ID}/dns_records?type=CNAME&name=*.${cluster}.${DOMAIN}"
    [ "$status" -eq 0 ]
    count=$(echo "$output" | jq '.result | length')
    [ "$count" -gt 0 ]
  done
}
