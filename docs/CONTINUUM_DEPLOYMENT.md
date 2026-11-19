# Proposed Hetzner deployment

Requires separate production authorization. Measure current state before making
changes. The following paths, service identity, and loopback port are proposed
and must be checked for conflicts on the host.

Record the current process identities, failed units, and representative HTTP
responses of neighboring applications before making changes. Pre-existing
application failures are baseline observations. Continue unless a condition
threatens shared infrastructure, data integrity, isolation, or the safety of
the proposed change. Compare the same signals after activation and stop to
assess any new failure plausibly caused by the release. Do not diagnose,
repair, restart, or change the configuration or data of a neighboring service
during a Continuum deployment.

The existing CE journal reporting failure (`EvidenceLimitError`) belongs to
the CE project. Record it as a baseline observation during v0.1.0 activation.
Keep CE trading controls, budgets, databases, and authorizations outside
deployment scope.

1. Create the dedicated `continuum` system user/group, a PostgreSQL LOGIN role
   `continuum` with no superuser/role/database creation privileges, and a new
   database `continuum_production` owned by that role. Use a private PostgreSQL
   endpoint with an explicit authentication rule. Keep existing application
   roles and databases out of the transaction.
2. Install Ruby 3.4.12 at `/opt/continuum/ruby` and resolve the locked bundle with
   `BUNDLE_DEPLOYMENT=true BUNDLE_WITHOUT=development:test`. Persist those
   settings in the release-local Bundler configuration so systemd uses the
   same release-local gems at startup. Install each
   verified revision under `/var/www/continuum/releases/<commit>` and use an
   atomically switched `/var/www/continuum/current` symlink. Verify the
   archived `VERSION` against the candidate release and retain prior releases.
3. Create `/var/www/continuum/shared/storage` owned by the service at mode 0700.
   Store `DATABASE_URL` (include a short PostgreSQL `connect_timeout`) and a
   generated `SECRET_KEY_BASE` in root-owned mode 0600
   `/etc/continuum/production.env`. Give the service read access only to
   `/var/www/site-art/public`. Add
   [the unit](../ops/continuum.service) to systemd and verify the dedicated
   service on free loopback port 4310. Probe `/up` and `/ready` with
   `Host: network.harvj.com` before adding public routes.
4. The infrastructure operator reviews [the new route](../ops/continuum.caddy)
   as `/etc/caddy/sites/continuum.caddy`, registers an explicit import and
   updates the infrastructure inventory. Use the infrastructure activation
   process and the exclusive `/etc/caddy/.configuration.lock` through
   full-graph validation, atomic install and graceful reload. Compare adapted
   configurations and verify adjacent sites before and after. Continuum's
   release identity does not receive Caddy configuration privileges.
5. Verify A/AAAA records for all three hosts and propose only missing or
   incorrect records after verifying the intended Hetzner addresses. Caddy
   supplies HTTPS. Probe root, `/up`, and `/ready` over verified TLS on each
   host. Confirm each footer matches the deployed `VERSION`, and verify links
   and the neutral or currently authorized background. Publish the GitHub
   release only after these production checks pass. See [versioning](VERSIONING.md).

Back up the database and persistent storage together off-server, encrypt
backups, and test restoration into an isolated service before imports. Restore
the dump to a fresh database using the dedicated role, restore media with the
original paths and ownership, point the isolated release to the restored
storage, then verify attachment data and checksums. Escrow production secrets
separately. Site Art backs up its own publication tree.

For application rollback, switch `current` to the prior verified release,
restart only `continuum.service`, and recheck both probes and all three hosts.
This release has no application migrations. For first-release withdrawal,
the infrastructure operator removes only Continuum's registration using
the shared lock and validation process, then stops the Continuum unit.
Preserve its database, media, release history and other routes. Artwork
rollback is a separate Site Art operation.
