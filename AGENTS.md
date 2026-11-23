# Continuum
# Working agreements

- Prefer simple, maintainable implementations with minimal dependencies.
- Preserve original source content and metadata without destructive transformations.
- Never modify original exports.
- Preserve Unicode, including Hebrew, Greek, Sanskrit, Tarot, and I Ching symbols.
- Write automated tests for importers and content transformations.
- Make import operations repeatable and eventually idempotent.
- Do not invent missing content, metadata, or symbolic relationships.
- Keep raw exports, credentials, and potentially private conversations out of Git.
- Never modify production services, DNS, or existing websites without explicit authorization.
- Use small, verifiable milestones.
- Keep project documentation accurate as the implementation evolves.
- Update `docs/STATUS.md` whenever a milestone is completed.
- At the end of each task, report changes, tests performed, and outstanding issues.

### Media storage conventions

- Self-host application media on the Hetzner server using Rails Active Storage with the local disk service.
- Do not introduce S3, cloud object storage, a CDN, or third-party media services without an explicit architectural decision.
- Store uploaded media in persistent storage outside application release directories.
- Preserve original image files, filenames where available, source URLs, and attribution metadata.
- Support images attached to Yods, hexagrams, articles, and other content entities.
- Keep media files out of Git, except small fixtures needed for automated tests.
- Ensure deployment procedures preserve persistent storage.
- Include application media in off-server backups and document restoration procedures.
- Do not delete original media during imports or migrations.
- Prefer Rails built-in functionality over custom storage infrastructure.

Continuum consumes the published Site Art snapshot with read-only access.
Keep the stable identifiers and schema in sync with [the Site Art contract](docs/SITE_ART.md).
Artwork selection and source registration belong to Site Art. Keep host-specific
icons and backgrounds on the same verified 30-second snapshot, with local
neutral fallbacks and content-addressed asset URLs. Verify changes with
synthetic fixtures in both repositories before registering any artwork.

### Production deployment isolation

- Baseline neighboring services with read-only checks. Record pre-existing
  failures and proceed with an independent Continuum release unless the
  condition threatens shared infrastructure, data integrity, isolation, or
  deployment safety.
- Compare the same signals after activation. Stop and assess new failures
  plausibly introduced by the release. Never repair or restart neighboring
  services as part of a Continuum deployment.
- Keep Continuum Engine trading controls, budgets, databases, and
  authorizations outside Continuum deployment scope.

## Simple Operations

Follow [Infrastructure Simple Operations v1.1](https://github.com/harvj/infrastructure/blob/main/docs/standards/simple-operations-v1.md). Use one dedicated non-root Unix account per application for deploy and runtime, with independent files, processes, writable directories, and PostgreSQL databases and roles. Restrict SSH and administrative access. Use one established deployment path (Capistrano for existing Rails apps) and one exact-release approval. Keep trusted CI, exact-artifact verification, reviewed migrations, verified backups and restore, health checks, and compatible application-only rollback. Prefer removing or consolidating controls. Explain the concrete need, existing alternatives, replacement, and upkeep before adding complexity. Obtain explicit operator approval for exceptions and new privileged machinery, required gates, persistent services, or authorization systems. Existing approved paths remain usable until individually migrated.

## Design review screenshots

For visual UI changes, retain a concise, representative set of actual browser screenshots under `docs/design/` in the application repository, with a short README and relative image links for GitHub review. Include relevant desktop/mobile and light/dark states; use before/after captures when useful. Temporary `/tmp` screenshots are development artifacts, not final review evidence. Do not add a new CI gate or enforcement mechanism for this convention.
