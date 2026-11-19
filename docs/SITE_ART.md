# Site Art contract

| Page | Logical identifier | Site Art source stem |
| --- | --- | --- |
| Network | `continuum.network_background` | `backgrounds/continuum/network` |
| Library | `continuum.library_background` | `backgrounds/continuum/library` |
| Intelligence | `continuum.intelligence_background` | `backgrounds/continuum/intelligence` |

Source extensions are WebP, PNG, JPG, JPEG or restricted SVG. Register sources
and provenance in Site Art. A successful push to `harvj/site-art/main` authorizes
publication. After one-time workflow commissioning, validated pushes publish
automatically using Site Art's restricted SSH credentials. Add or replace a
source using its stable ID. Remove its entry to withdraw it from the current
snapshot while retaining historical assets and provenance.

The v1 manifest at `https://art.harvj.com/manifest.json` has `schema_version`,
`commit`, `release`, and an `assets` object keyed by logical ID. Records have
`url`, `sha256`, `bytes`, `media_type`, and `rights`. The release digest is
the SHA-256 of compact ASCII-escaped JSON with recursively sorted object keys,
a final LF, and the `release` member omitted. Public artwork URLs follow
`https://art.harvj.com/assets/<sha256>.<extension>`.

The publisher validates and installs immutable files before atomically changing
the manifest. An invalid or interrupted pre-activation publication leaves the
active snapshot intact. Rollback selects a verified retained release using the
Site Art workflow. A failed post-activation probe calls for checking the active
release before retrying because the manifest may already have changed.

Continuum reads the published directory on the shared host with read-only
access, verifies the release and artwork hashes, and serves verified background
bytes from memory on digest-addressed routes. It polls on demand at most once
every 30 seconds per process. On a fresh page navigation, changes appear within
30 seconds of activation under steady traffic. Idle processes refresh on their
next request. Open pages show the background selected when they loaded.

Cold starts with unavailable or invalid data show a neutral surface. Transient
read or checksum failures keep the last verified in-process snapshot. Successful
removal drops that background. Requests need neither a Site Art process nor an
HTTP fetch. The same resolver can be given additional logical IDs when future
Yod and wiki integrations are built. Continuum has no publication credentials.
