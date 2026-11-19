# Hetzner deployment preparation — proposal only

For the current v0.1.0 proposal, see [Continuum deployment](CONTINUUM_DEPLOYMENT.md).

As of P1.0 (2026-11-15), no deployment infrastructure or runbook exists in the
repository. Existing documentation establishes media storage policy, not actual
server configuration. Nothing below has been applied or verified on the server.
Do not include credentials or private server inventory in Git.

## Information required before proposing exact configuration

| Area | Evidence needed for safe coexistence |
| --- | --- |
| Server and access | Intended Hetzner host, OS, architecture, approved access method/account, privilege boundaries and service owner; no assumption that credentials work |
| Existing applications | Domains, proxy/site configs, service/container names, listening ports, release/storage paths, scheduled jobs and maintenance windows; identify protected workloads |
| Capacity/runtime | CPU/RAM/disk headroom, storage growth and image-variant budget, installed Ruby/PostgreSQL/runtime tools; assess build and migration load |
| Reverse proxy/TLS | Proxy software and config ownership, existing host rules, available upstream binding, certificate issuance/renewal method and authorized reload procedure |
| Database | Existing cluster/version, permitted database/role creation, least-privilege app role, connection limits, migration role and backup/restore permissions; no assumption of superuser access |
| Persistent files | Approved app-specific release/config/storage paths, disk mount persistence, ownership, permissions, free space and backup inclusion |
| Secrets | Approved provisioning and rotation method for Rails credentials/master key and database password; recovery access; never print secrets into reports |
| DNS | Current records for all three subdomains, zone owner/provider, intended target, TTL and rollback values; no assumption that any host points to Hetzner |
| Backup/recovery | Existing jobs, retention, encrypted off-server destination, restore owner, recovery objectives, restore-test evidence and coverage of database, media and needed configuration |
| Operations | Deploy owner, isolated staging approach, health checks, logs/rotation, monitoring, restart policy, rollback and maintenance policy |

## Proposed topology and changes for later review

- One Rails application process/service (or its selected deployment equivalent)
  and one app-specific PostgreSQL database/role serve all three hosts. Separate host
  routes and navigation inside the app; shared content and media records.
- Add only approved host-specific proxy entries for `network.harvj.com`,
  `library.harvj.com` and `intelligence.harvj.com`, pointing to an isolated local upstream. Preserve
  existing catch-all behavior and other application configurations.
- Allocate app-specific release and shared configuration directories. Proposed
  example layout is `/var/www/continuum/releases/`, `/var/www/continuum/shared/storage/` and
  an app-specific secrets location; these paths are placeholders pending inspection.
  Configure Active Storage disk root to the shared absolute storage path. Release
  cleanup must never traverse shared storage or source archives.
- Keep originals and provenance during migration. Serve application media locally
  through Rails/approved proxy integration. No S3, external CDN or third-party media.
- Add database and media backups to an approved off-server destination. Preserve
  attachment/blob records and disk bytes together, archive source manifests, and
  document secure restoration of required configuration/keys.
- Choose the simplest deployment mechanism compatible with existing operations
  after inspection; no assumption that Docker, Kamal, systemd or a particular proxy
  is already installed or appropriate.

## Guarded rollout and recovery gates for P1.4

1. Obtain authorized read-only server facts and produce an exact, reviewable diff
   of proposed services, paths, roles, proxy entries and DNS changes. Identify any
   shared reload/restart impact and conflicts before making changes.
2. Validate application tests, import/rerun counts, host routing and both independent
   navigation surfaces in an isolated environment. Review public content, source
   attribution, media URLs, sanitization and private-content exclusion.
3. Prepare runbooks for initial data/media transfer, migrations, health checks,
   backup and rollback. Back up before migrations. Prefer reversible or compatible
   schema changes; a previous application release may not fit a migrated database.
4. Rehearse restore into an isolated database and disk root: restore the database,
   original media and configuration; verify attachment hashes, counts and both
   interfaces. Record recovery timing and verify no effect on other applications.
5. Obtain explicit authorization for concrete production service changes and DNS
   changes, then perform only that approved scope. Syntax-check proxy config before
   any approved reload. Verify TLS and both hosts plus existing applications.
6. Roll back to recorded proxy/DNS/release settings on failed acceptance. Restore
   database only under the reviewed recovery plan, accounting for writes since the
   backup. Never delete shared media during rollback. Confirm off-server backup
   success after launch and record operational ownership.

No SSH, database provisioning, package installation, service reload, uploads,
certificate requests, DNS modification or deployment was performed during P1.0.
