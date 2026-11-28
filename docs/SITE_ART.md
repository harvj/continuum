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
[Site Art consumer presentation specification v1](https://github.com/harvj/site-art/blob/main/ops/presentation-spec-v1.md)
defines treatment for ordinary content, the header and navigation, and the
footer. Each role resolves its foreground, glyph shadow, and backing
independently, with regional values overriding flat values. The footer is
the designated backing surface. Structured foreground takes precedence over
the legacy `light` and `dark` tokens and the host's neutral foreground.

Continuum serves the background and treatment from the same verified snapshot.
The browser starts with the host's neutral theme and reveals the background
and treatment together after decoding. A failed decode leaves the neutral
theme in use. A plain artwork record uses Continuum’s legacy legibility
surfaces. Forced colors uses the system theme. Metadata-only updates
apply on the next navigation and keep the same immutable image URL.

The page advertises the
host-specific favicon with `rel="icon"` and its MIME type. An SVG advertises
`sizes="any"`; an optional PNG link precedes it. With no assigned favicon,
Continuum serves a transparent placeholder. Each host's stable `/favicon.ico`
redirects with `Cache-Control: no-store`, preferring PNG when available.
Digest-addressed image responses are immutable for one year. New image bytes
produce a new URL. Browsers or pinned shortcuts can retain an icon until
navigation or browser refresh.

The publisher installs verified immutable files before atomically replacing
the manifest. A failure before activation leaves the prior snapshot active.
Continuum retains the last verified in-process snapshot on an invalid
envelope, a release digest mismatch, or missing or corrupt referenced bytes.
An absent ID or invalid core record uses the local fallback for that ID.
Unknown optional fields are ignored, and invalid optional values leave valid
fields and images usable. A cold start with no valid snapshot uses the neutral fallbacks.
The Site Art rollback workflow selects a verified retained release. If a
post-activation probe fails, check the active release before retrying.

After one-time commissioning, a validated push to `harvj/site-art/main`
authorizes publication. Publication and rollback need no Continuum restart,
configuration change or redeployment. Continuum has no publication credentials.
See [release readiness](RELEASE_v0.1.1.md) for current commissioning status.

## Network day and night artwork

Site Art publishes the approved Network pair as
`continuum.network_background_light` and
`continuum.network_background_dark`. Continuum uses the variants and their
separate treatments from the same verified snapshot. A complete pair enables
the Network appearance control. The anonymous page follows the system setting
until a visitor chooses a mode. A single remaining variant can render on its
own when the original Network ID is absent, and it leaves any saved preference
intact. Library and Intelligence use their single approved backgrounds.
