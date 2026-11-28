# Continuum v0.2.0

Continuum v0.2.0 gives Network, Library, and Intelligence one shared sign-in. Start on any host through White Sands, then move among all three directly. The verified username and currently authorized application destinations follow the same Continuum session. Signing out on any host ends that session everywhere and revokes its originating Auth grant.

All three landing pages remain publicly accessible. Each host keeps its own browser cookie, so Continuum’s session cookie is never sent to other harvj.com applications. The three existing Auth callback registrations remain in use. Auth administrator MFA is unchanged.

Network now offers System, Light, and Dark when both approved Site Art variants are available. Library and Intelligence retain their approved backgrounds and footer treatments. The credit links to Jim Harvey’s homepage, and Intelligence has a distinct two-tone focus indicator.

The release was qualified against the signed Continuum-specific Application Shell v2.3.0 dispositions. It passed live White Sands journeys from all three hosts, including logout from a different host. The deployment uses additive Continuum-only database migrations, with the prior application artifact retained for rollback.

Deployed source: `3de4a58d7de5d2090ba6a81ea5b6813454bb44b2`

Release archive SHA-256: `9a37977e17900bfa254fcc60a5720bc7c20f44569f8332f52e35db09a85d7cec`
