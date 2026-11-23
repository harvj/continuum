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


### Application Shell qualification

- Keep optional Shell v2 evidence in [docs/qualification](docs/qualification) and
  use the signed current v1.3.0 baseline for production preflight.
- Use the exact reviewed Infrastructure approval revision recorded in the
  [v2 qualification](docs/qualification/APPLICATION_SHELL_V2.md). Only the
  listed Library and Intelligence footer text and credit crops are eligible.
  Test the credit target, accessible name, keyboard reachability, wrapping,
  and visible focus independently.
- Record measured ratios and keep `pass`, `approved_exception`, and
  `unresolved` distinct. Refer below-target cases outside the approval to
  review. Requalify material artwork, crop, foreground, typography, markup,
  or accessibility changes. Keep qualification approval IDs out of signed
  fixtures and production preflight records.
