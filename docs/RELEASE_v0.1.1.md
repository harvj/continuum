# v0.1.1 — Background and Favicon Integration

## What changes

Network, Library, and Intelligence each resolve a background and favicon from
the locally mounted Site Art publication. The background identifiers and display
rules carry forward, including proportional viewport coverage and separate text
surfaces for header and footer legibility. Each hostname advertises its own SVG
or PNG favicon, with optional PNG fallback for SVG. Until Site Art assigns
assets, the page uses its existing neutral background and a transparent icon.

The manifest stays at schema version 1. The new favicon identifiers are additive
and leave Auth, Muzeum, and Continuum Engine conventions intact. Continuum
checks the manifest digest and asset bytes as one snapshot, on demand no more
than once per process every 30 seconds. Publication, replacements, withdrawals,
and rollback take effect on navigation after refresh. Transient errors retain
the last verified snapshot, and a cold start can render with no snapshot.

The host-local `/favicon.ico` discovery route redirects without caching the
selection. Icon links use immutable digest-addressed paths, so a replacement
receives a new browser cache key. Browser tabs and bookmarks may refresh the
icon on their own schedule. Artwork rendering needs no network fetch from Rails,
and future artwork publication does not require a Continuum release.

## Verification and rollout

The Rails suite covers per-host artwork, neutral fallback, the refresh boundary,
cache headers, manifest validation, replacements, rollback, liveness and database
readiness. The Site Art suite verifies the additive identifiers and format rules
with the existing publication, security, provenance, and Caddy tests.
Chromium verified 25 fixture navigations across all three hosts at 1440×900
and 390×844. A single Rails process rendered the neutral state, first
publication, replacements, and the restored snapshot after a publisher
rollback.

This is a local candidate. No Continuum artwork is registered in the live Site
Art manifest. GitHub rejected the latest Site Art validation run before any
steps ran because of billing or spending limits. The production workflow
requires the existing one-time commissioning variable
`ART_AUTO_PUBLICATION_ENABLED`, which is unset. Once commissioned, a validated
main push is sufficient authorization. No additional approval is required.

See the [shared contract](SITE_ART.md) and [versioning procedure](VERSIONING.md).
