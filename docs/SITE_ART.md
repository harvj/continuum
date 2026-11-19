# Site Art contract

| Page | Background ID | Primary favicon ID | Optional PNG fallback ID |
| --- | --- | --- | --- |
| Network | `continuum.network_background` | `continuum.network_favicon` | `continuum.network_favicon_png` |
| Library | `continuum.library_background` | `continuum.library_favicon` | `continuum.library_favicon_png` |
| Intelligence | `continuum.intelligence_background` | `continuum.intelligence_favicon` | `continuum.intelligence_favicon_png` |

Register reviewed sources and provenance in Site Art. Background sources go
under `backgrounds/continuum/<section>` with a WebP, PNG, JPG, JPEG or
restricted SVG extension. The primary favicon is
`favicons/continuum/<section>/favicon.svg` or `favicon.png`. The optional
fallback uses `favicon.png` and is useful when the primary is SVG. The fallback
also works on its own. Replacements keep their logical ID. Remove an entry to
withdraw it while retaining historical bytes and provenance.

The v1 manifest at `https://art.harvj.com/manifest.json` has `schema_version`,
`commit`, `release`, and an `assets` object keyed by logical ID. Records have
`url`, `sha256`, `bytes`, `media_type`, and `rights`. The release digest is
the SHA-256 of compact ASCII-escaped JSON with recursively sorted object keys,
a final LF, and the `release` member omitted. Public artwork URLs follow
`https://art.harvj.com/assets/<sha256>.<extension>`. Favicons add IDs using
these same fields. Their media type and extension identify PNG or SVG.

Continuum reads the published directory on the shared host with read-only
access, verifies the release and all referenced Continuum assets, and adopts
one complete snapshot. It polls on demand at most once every 30 seconds per
process. A new navigation sees the new snapshot after refresh. Open pages
retain their current artwork. Requests require neither a Site Art process nor
HTTP access to its public endpoint.

Backgrounds retain their intrinsic proportions and cover the viewport. The
optional `foreground` field selects `light` or `dark` for text and icons over
the image. Site Art chooses this value for the reviewed crops. The field and
image belong to the same verified snapshot. A metadata-only publication keeps
the image URL and applies on navigation after refresh. A record without the
field uses the host's neutral foreground. An absent background uses the
existing host-specific neutral surface and foreground. The page advertises the
host-specific favicon with `rel="icon"` and its MIME type. An SVG advertises
`sizes="any"`; an optional PNG link precedes it. With no assigned favicon,
Continuum serves a transparent placeholder. Each host's stable `/favicon.ico`
redirects with `Cache-Control: no-store`, preferring PNG when available.
Digest-addressed image responses are immutable for one year. New image bytes
produce a new URL. Browsers or pinned shortcuts can retain an icon until
navigation or browser refresh.

The publisher installs verified immutable files before atomically replacing
the manifest. A failure before activation leaves the prior snapshot active.
Continuum retains the last verified in-process snapshot on malformed data,
missing files or checksum errors. A valid manifest with an ID removed drops
its image. A cold start with no valid snapshot uses the neutral fallbacks.
The Site Art rollback workflow selects a verified retained release. If a
post-activation probe fails, check the active release before retrying.

The first release with `foreground` requires a compatible Continuum deployment
and Site Art publisher verifier. Both accept older v1 releases without the field.
After one-time commissioning, a validated push to `harvj/site-art/main`
authorizes publication. Publication and rollback need no Continuum restart,
configuration change or redeployment. Continuum has no publication credentials.
See [release readiness](RELEASE_v0.1.1.md) for current commissioning status.
