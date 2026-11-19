# Continuum

Continuum serves Network, Library and Intelligence from one Rails application
with PostgreSQL. The three landing pages share navigation and a footer and
display [published Site Art backgrounds](docs/SITE_ART.md) when available.
WE R NI and WE R AI are historical publication names.

Use Ruby 3.4.12 and PostgreSQL locally. Run `bundle install`,
`bin/rails db:prepare`, and `bin/rails server`. Send a supported host name to
the local server, for example `curl -H 'Host: network.harvj.com' localhost:3000`.
Run `bin/rails test`. Set `CONTINUUM_TEST_POSTGRES=1` with a prepared
`continuum_test` database to exercise database readiness.

- [Numbered roadmap](docs/ROADMAP.md)
- [Status](docs/STATUS.md)
- [Proposed deployment](docs/CONTINUUM_DEPLOYMENT.md)
- [v0.1.0 release notes](docs/RELEASE_v0.1.0.md)

## Repository structure

- `AGENTS.md`: working agreements for contributors and agents.
- `docs/STATUS.md`: current milestone, results, issues, and next possible tasks.
- `docs/SQUARESPACE_INVENTORY.md`: generated, reviewable inventory summary.
- `scripts/squarespace_inventory.py`: local inventory utility.
- `tests/fixtures/`: small synthetic XML fixtures, safe to version-control.
- `source/squarespace/`: local original XML exports, excluded from Git.
- `tmp/inventory/`: generated JSON, excluded from Git.

## Run the inventory

Requires Python 3.9+; no third-party packages or network access are needed.
Place original Squarespace WordPress XML exports in `source/squarespace/`, then run:

```sh
python3 scripts/squarespace_inventory.py --expect-count 37
python3 -m unittest discover -s tests -v
```

The utility reads all lowercase `*.xml` files in that directory and writes
`tmp/inventory/squarespace.json` and `docs/SQUARESPACE_INVENTORY.md`. Optional
`--source-dir`, `--output-dir`, and `--summary` flags override these locations.
It returns a nonzero exit status for parsing problems, missing required fields,
or an unexpected item count, while still writing results from readable exports.
Missing values remain null; dates and URL references retain their exported form.
Links and image references are deduplicated in first-seen order. Paths are derived
from exported links without inventing a host or resolving relative references.

JSON includes readable text, anchor links, image element references (including
lazy-loading attributes and source sets), original HTML, and serialized item XML
for additional metadata. Readable text omits scripts and styles and normalizes
whitespace; original HTML is retained separately. Image references embedded only
in CSS or JavaScript are not extracted. Original exports remain the authoritative
byte-for-byte source; serialized XML may use different namespace prefixes.
No images are downloaded and no external services are accessed.

Repeated runs on unchanged input produce the same inventory. This is an inventory,
not an application importer; application-level idempotency is future work. Keep raw
exports, generated JSON, credentials, and private conversations out of Git. Review
the Markdown summary for sensitive titles and paths before staging it.
