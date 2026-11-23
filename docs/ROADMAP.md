# Continuum — Numbered launch roadmap

Baseline: 2026-11-15. P1.0 is complete as a local assessment; P1.1 onward is
planned. [Status](STATUS.md) records verification and remaining uncertainties.

## Architecture governing every milestone

One Rails application and PostgreSQL database serve `network.harvj.com`,
`intelligence.harvj.com` and `library.harvj.com`, with independently navigable host-specific interfaces over
shared source records. Cross-interface links reuse content identities. Preserve
original files, URLs, publication metadata, attribution, links and media provenance;
unknown information stays unknown. Keep immutable source evidence apart from
sanitized rendering and derived text.

Use Rails Active Storage local disk on Hetzner, with persistent media outside
release directories and off-server backups. No S3, external CDN, or third-party
media service. Media attachments must support Yods, hexagrams, articles and future
entities. Keep Yod identity, tableau placement and content relationships separate.
Allow independently addressable concepts (integers, Hebrew words, correspondences)
without inventing symbolic relationships. AI interaction enters scope at P2.2.

## P1.0 — Repository assessment and migration baseline

**Complete.**

1. Record Git state and distinguish committed code, working-tree code, local
   artifacts and planned functionality.
2. Inspect every utility/test; rerun tests and real-export inventory; reconcile
   all 37 pages and verify preserved originals against the manifest.
3. Document extraction limits, shared architecture, first implementation steps
   and missing deployment facts without changing infrastructure.

Acceptance: [assessment](P1.0_ASSESSMENT.md), this roadmap, updated status,
[P1.1 plan](P1.1_PLAN.md), and [deployment preparation](DEPLOYMENT_PREPARATION.md);
15 passing tests, repeatable 37-page inventory, 55 checksum-verified images.

## v0.1.1 — Background and Favicon Integration

The local candidate completes the three host-specific [Site Art bindings](SITE_ART.md)
for backgrounds and SVG/PNG favicons. Site Art owns artwork selection and
publication. Independent publication and rollback refresh the unchanged Rails
process. See the [release notes](RELEASE_v0.1.1.md) for verification and the
remaining production commissioning work.

## P1.1 — Rails foundation, shared content model, and repeatable import

**Next.** Detailed sequence and acceptance criteria: [P1.1 plan](P1.1_PLAN.md).

1. Rails/PostgreSQL, pinned dependencies, host routing and application tests
   are delivered in the v0.1.0 foundation.
2. Model immutable source evidence, shared content, explicit relationships and
   media provenance; separate stable Yod identities from layout.
3. Build a dry-run/transactional importer with stable source keys, database
   uniqueness, run reports, additive reconciliation and unchanged-rerun guarantees.
4. Attach checksum-verified local originals through built-in Active Storage;
   preserve manifests, original filenames and source attribution.
5. Verify all 37 records, Unicode, metadata, links, media reuse, failure recovery,
   unchanged reruns, changed-source handling and original-file immutability.

Exit: local application and importer work from documented inputs on a fresh
supported environment; no public launch or inferred content relationships.

## P1.2 — Intelligence tableau and 22 Yod pages

**Planned after P1.1.**

1. Review an explicit mapping from all 22 exported Tarot pages to Yod identities
   0–21; do not derive identity from record order or tableau coordinates.
2. Store a separate versioned tableau configuration. Proposed column-major
   layout: first column 1–7, second 8–14, third 15–21; Fool (0) directly above
   Magician (1), not a fourth seven-card row. Review this reading order against
   source evidence before final visual acceptance.
3. Render the Intelligence home tableau and individually addressable Yod pages
   with preserved content, provenance, sanitized HTML, local media and explicit
   links. Choose originals or reviewed derivatives; Devil previews do not imply
   approval of all 22 card treatments.
4. Provide complete keyboard navigation, accessible card names, visible focus,
   responsive layout that preserves logical order, and stable page URLs. Provide
   a host-aware link to Library; full Library search arrives in P1.3.
5. Test exactly one of each identity 0–21, unique placements, Fool/Magician
   alignment, host routing, page coverage, safe rendering, Unicode and links.
   Review desktop and mobile layouts and all artwork for cropped symbols.

Exit: Intelligence is locally navigable independently through all 22 pages;
shared source records remain single records; no deployment is implied.

## P1.3 — Searchable Library and cross-domain navigation

**Provisional.** Search original articles, individual human prompts, AI responses
and other content with provenance and context. Use PostgreSQL capabilities first;
choose multilingual indexing from actual content and tests. Make Library independently
navigable and connect both interfaces using canonical shared record identities.
Role-specific results depend on verified segmentation, not guessed speaker labels.

## P1.4 — Guarded Hetzner deployment and public launch

**Provisional.** Resolve the [deployment checklist](DEPLOYMENT_PREPARATION.md),
prepare reviewable configuration, validate isolated rollout, restore and rollback,
then obtain explicit authorization for production service/DNS changes. Launch both
hosts only after content, media, navigation and backup acceptance.

## P1.5 — Application Shell readiness and Auth onboarding

**Recommended next Shell milestone.** Public Network, Library and Intelligence
remain anonymously accessible. Coordinate this milestone with P1.1 content
foundation, P1.3 navigation and the access model for editorial tools and P2.2
Network features, before launching any protected workflows.

1. Close the contrast gaps in the approved public artwork crops and qualify
   the fixes with the published fixture set.
2. Add durable candidate number allocation, exact archive and launch binding,
   authenticated acceptance/publication receipts and same-process footer
   refresh. Rehearse failure retention and rollback before replacing the
   existing production version path.
3. Agree on client registration, canonical hosts and callbacks with Auth.
   Implement the approved OIDC login, local authenticated session, logout
   and invalidation only when the protected workflows have defined needs.
4. Retain verified subject and username with the local session. Fetch fresh
   session-bound grants independently for protected navigation. Exercise
   outages, expiry, delayed responses, restoration, replacement and real
   invalidation. Verify authorization at protected destinations as well as
   in the application switcher.
5. Exercise the Network appearance control on the same surface in both
   authentication states, and retain the saved preference through login and
   logout. Keep the control hidden on single-variant hosts. Complete signed
   registry refresh and candidate-bound preflight evidence before requesting
   v2 adoption.

See the [v2 qualification and Auth inventory](qualification/APPLICATION_SHELL_V2.md).
P1.1 remains the next content milestone.

## P2.0 — Medium/Substack migration and conversation extraction

**Provisional.** Inventory actual exports, preserve source evidence and publication
metadata, deduplicate only with evidence, and extract individually addressable
human prompts/AI responses with context and reviewed roles. Evolve P1.3 search as
verified content becomes available. Do not add AI chat.

## P2.1 — Expanded symbolic encyclopedia and contextual navigation

**Provisional.** Extend addressable concepts, integers, Hebrew words, hexagrams
and correspondences with explicit provenance and contextual links. Evolve schemas
and navigation from evidence rather than filling absent symbolic relationships.

Later milestone scope and acceptance criteria will be refined from implementation
and source evidence. Each completed milestone updates `docs/STATUS.md`.

## P2.2 — Network AI

Define the Network experience and verify interaction and access requirements
with the existing Auth service before implementation.
