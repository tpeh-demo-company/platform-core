from typing import Optional

import pulumi_kubernetes as k8s
from pulumi import Input, ResourceOptions


def create_tunnel_credentials_secret(
    credentials_json: Input[str],
    namespace: str = "cloudflare-system",
    provider: Optional[k8s.Provider] = None,
) -> k8s.core.v1.Secret:
    ns = k8s.core.v1.Namespace(
        "cloudflare-system",
        metadata=k8s.meta.v1.ObjectMetaArgs(name=namespace),
        opts=ResourceOptions(provider=provider, retain_on_delete=True),
    )

    return k8s.core.v1.Secret(
        "cloudflare-tunnel-credentials",
        metadata=k8s.meta.v1.ObjectMetaArgs(
            name="cloudflare-tunnel-credentials",
            namespace=namespace,
        ),
        string_data={"credentials.json": credentials_json},
        opts=ResourceOptions(
            provider=provider,
            depends_on=[ns],
            retain_on_delete=True,
        ),
    )
