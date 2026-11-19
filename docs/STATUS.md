# Continuum status

## v0.1.1 Background and Favicon Integration

The local candidate binds each hostname to the existing background ID and its
own SVG or PNG favicon in the verified 30-second Site Art snapshot. Production
remains on v0.1.0. No Continuum artwork is registered in the public manifest.

Verified with PostgreSQL (9 Rails tests, 174 assertions), 4 inventory tests,
35 Site Art tests with Caddy, and 25 Chromium navigations on three hosts at
1440×900 and 390×844. An unchanged Rails process rendered neutral fallbacks,
first publication, replacements and rollback from disposable Site Art snapshots.

Automatic Site Art publication is blocked. The latest validation job did not
start because of GitHub billing or spending limits, and the commissioning
variable is unset. See [release notes](RELEASE_v0.1.1.md) and the
[Site Art contract](SITE_ART.md).

## v0.1.0 application foundation

The v0.1.0 candidate now reads the committed version at boot and verifies
release tags against the exact revision. See [versioning](VERSIONING.md).

The repository and checkout are named Continuum. Rails now serves the three
host-specific landing pages. See the [release notes](RELEASE_v0.1.0.md),
[Site Art contract](SITE_ART.md), and [deployment plan](CONTINUUM_DEPLOYMENT.md).
The migration baseline below records the historical tool and export status.
The next implementation milestone is the P1.1 content model and importer.

Verified locally: Rails integration tests with PostgreSQL (3 tests, 64
assertions), the inventory and image suites (15 tests), Site Art (33 tests),
Brakeman, the Ruby advisory database, and Chromium at 1440×900 and 390×844.
Production v0.1.0 is deployed at
`2be1a7c8d7652fc989753885a05e77b1047be2d5`.
Network, Library, and Intelligence returned the exact v0.1.0 footer over
HTTPS and passed liveness and database readiness. The Rails suite passed with
PostgreSQL (7 tests, 88 assertions), and GitHub CI and exact tag verification
passed. The first GitHub release was published after verification.
Neighboring applications matched their baselines. The dedicated database
and persistent media directory were empty at bootstrap. Commissioning
automatic Site Art publication and confirming an off-server backup destination
remain separate work before content imports.

Updated: 2026-10-29

## Historical inventory milestone

Completed: repository documentation and first local Squarespace content inventory.

## Completed work

- Documented WE R NI, the two planned interfaces, shared content, migration sources,
  working agreements, and the intended Rails/PostgreSQL stack (not implemented).
- Added a dependency-free Python inventory utility, synthetic XML fixtures, and tests.
- Inventoried the local Squarespace export: **37 items, all pages, 0 reported problems**.
- Generated `docs/SQUARESPACE_INVENTORY.md` and ignored
  `tmp/inventory/squarespace.json` with text, metadata, HTML, links, and image references.
- Verified all 4 automated tests pass, including Unicode, missing fields, malformed
  XML, repeatability, CLI outputs/count validation, and source-directory write protection.
- Verified another real-export run left the source unchanged and produced byte-identical
  JSON and Markdown outputs. Confirmed Git ignores raw exports, generated JSON,
  credentials, and local environments. No commits or pushes performed.

## Known issues and limits

- Image URLs embedded only in CSS or JavaScript are not extracted; HTML is retained.
- Readable text normalizes whitespace; the export remains the authoritative original.
- Multiple exports are inventoried independently; overlapping records are not merged.
- Application import, search and symbolic relationship models remain future work.
- Medium and Substack exports have not been inventoried.

## Next possible tasks

1. Review inventory text and image/link coverage against the original pages locally.
2. Inventory Medium and Substack exports with similarly small tested utilities.
3. Define shared content identities, provenance, and explicit relationship rules before
   building an idempotent importer and the Rails/PostgreSQL application.

Resume with `python3 -m unittest discover -s tests -v` and
`python3 scripts/squarespace_inventory.py --expect-count 37`.
