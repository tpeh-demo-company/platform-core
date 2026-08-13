"""Shared platform infrastructure — Auth0 IdP + Cloudflare Tunnels"""

from modules.auth0 import (
    GROUPS_CLAIM,
    Auth0ClientConfig,
    Auth0RoleConfig,
    create_groups_action,
    create_kubernetes_client,
    create_role,
)
from modules.cloudflare import CloudflareTunnelConfig, create_tunnel

import pulumi

# Config
config = pulumi.Config()
auth0_cfg = pulumi.Config("auth0")
cf_cfg = pulumi.Config("cloudflare")
clusters = config.require_object("clusters")
roles = config.require_object("roles")

# Action
create_groups_action()

# Roles
for role in roles:
    role_cfg = Auth0RoleConfig(
        name=role["name"],
        description=role.get("description", ""),
    )
    create_role(role_cfg)

# Clients
k8s_clients = {
    cluster: create_kubernetes_client(Auth0ClientConfig(name=f"kubernetes-{cluster}"))
    for cluster in clusters
}

# Tunnels
cf_tunnels = {
    cluster: create_tunnel(
        CloudflareTunnelConfig(
            cluster=cluster,
            domain=config.require("domain"),
            account_id=cf_cfg.require("accountId"),
            zone_id=cf_cfg.require("zoneId"),
        )
    )
    for cluster in clusters
}

# Outputs
pulumi.export("oidc_groups_claim", GROUPS_CLAIM)
pulumi.export(
    "auth0_issuer_url",
    pulumi.Output.concat("https://", auth0_cfg.require("domain"), "/"),
)
for cluster, client in k8s_clients.items():
    pulumi.export(f"auth0_client_id_{cluster}", client.client_id)
for cluster, credentials in cf_tunnels.items():
    pulumi.export(f"cloudflare_tunnel_credentials_{cluster}", credentials)
