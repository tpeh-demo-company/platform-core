import json
from dataclasses import dataclass

import pulumi_cloudflare as cloudflare
import pulumi_random as random

import pulumi


@dataclass
class CloudflareTunnelConfig:
    cluster: str
    domain: str
    account_id: str
    zone_id: str


def create_tunnel(config: CloudflareTunnelConfig) -> pulumi.Output:
    secret = random.RandomBytes(
        f"cloudflare:tunnel:{config.cluster}:secret",
        random.RandomBytesArgs(length=32),
        opts=pulumi.ResourceOptions(additional_secret_outputs=["base64"]),
    )

    tunnel = cloudflare.ZeroTrustTunnelCloudflared(
        f"cloudflare:tunnel:{config.cluster}",
        cloudflare.ZeroTrustTunnelCloudflaredArgs(
            account_id=config.account_id,
            name=config.cluster,
            secret=secret.base64,
            config_src="local",
        ),
    )

    # Wildcard CNAME: *.{cluster}.{domain} → <tunnel-id>.cfargotunnel.com
    cloudflare.Record(
        f"cloudflare:dns:{config.cluster}:wildcard",
        cloudflare.RecordArgs(
            zone_id=config.zone_id,
            name=f"*.{config.cluster}",
            type="CNAME",
            content=tunnel.id.apply(lambda tid: f"{tid}.cfargotunnel.com"),
            proxied=True,
        ),
        opts=pulumi.ResourceOptions(depends_on=[tunnel]),
    )

    # Credentials JSON for the cloudflared Deployment (to be SOPS-encrypted in platform-services)
    return pulumi.Output.secret(
        pulumi.Output.all(
            account_id=config.account_id,
            secret=secret.base64,
            tunnel_id=tunnel.id,
        ).apply(
            lambda v: json.dumps(
                {
                    "AccountTag": v["account_id"],
                    "TunnelSecret": v["secret"],
                    "TunnelID": v["tunnel_id"],
                }
            )
        )
    )
