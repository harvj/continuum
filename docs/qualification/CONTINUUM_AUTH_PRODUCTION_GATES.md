# Continuum Auth integration and production decisions

Continuum remains on v0.1.2 in production. The v0.2.0 release still requires
a passing candidate-bound signed Shell v1.3.0 preflight. The optional
[v2 qualification](APPLICATION_SHELL_V2.md) and the
[previous failed production preflight](CONTINUUM_V0.2.0_PREFLIGHT.md) are
separate records.

## Signed v1.3.0 requirements

The verified manifest is
`dd810b8879c71a206af652885cce5c84cb10022dfa3ae9480ed66dc73580771b`,
the registry is
`06f064e98025a06d195c76654fade82f5976aa2c1b946fb600052098814b360e`,
and the fixtures are
`321234fa59f2110e94e47896e22c82a0f03b635cf477762b41329630fb1acd78`.
The signed policy lists no Continuum exception.

| Prior failure | Work and ownership |
| --- | --- |
| SH-02 anonymous entry | Continuum now has a deliberate host-local `/login` entry and public root. Signed §3 and the SH-02 fixture also require a visible same-origin Log In link. Hiding it in favor of Auth-owned entry requires an explicit Infrastructure decision and version-scoped signed applicability. The Home icon is gone. |
| SH-03 and SH-05 session and disclosure | Continuum implements host-local sessions, a verified username, account settings and CSRF-protected logout. Auth must confirm production client registrations, assurance, evidence availability and entry links before the real three-host journey can qualify. |
| SH-04 and SH-09 registry | Continuum consumes the protected local runtime cache produced by Infrastructure's signed verifier. Positive eligibility is intersected with the ordered production registry. Validate the verifier service identity, persistent cache ownership and periodic refresh with the deployer before enabling production Auth. |
| SH-06 contrast | The earlier v2 approvals concern only the recorded Library and Intelligence footer text crops. They are outside the signed v1.3.0 policy. Infrastructure owns the production disposition and any version-scoped approval. Focus stays a separately tested requirement. |
| SH-07 release | Retain the packaged-version footer and exact tag/rollback tests. Numbered immutable candidates, authenticated publication receipts and same-process promotion remain separate v2 roadmap work. |

## Continuum-owned authentication

The consumer follows Auth v0.5.0 at
`d0376d51c94764c59442193d2dccd27e8392dbf8`, including
`docs/integrations/application-login.md` and
`docs/integrations/application-shell-v1.md`. White Sands stays on Auth. An
existing White Sands browser cookie is host-only to Auth and conveys no
Continuum identity. A deliberate link from Auth to a registered Continuum
`/login` can reuse sufficient Auth assurance through normal top-level OIDC
and establish a Continuum session on callback. Root pages perform no
authorization redirect, iframe check or silent OIDC. A Continuum session
belongs to exactly one host. Visiting the other two public hosts remains
anonymous until they complete their own authorized journeys.

Each configured host uses the library's Authorization Code client with
S256 PKCE, a one-use expiring PostgreSQL attempt, state, nonce, and a host-only
browser binding. The callback validates the signed ID token, including
issuer, subject, audience, authorized party, deadline, nonce and any
configured assurance requirement. The scoped opaque access handle is
encrypted server-side. The session cookie carries an opaque random value;
the database stores its digest. Local sessions end by the access-token
deadline or five minutes at most. The application requests `openid` only,
with no refresh or offline-access assumption.

Authenticated requests introspect that session's owned grant. Explicit
inactivity invalidates the local session. An unavailable response keeps
previously verified identity within the local deadline and yields no
application links. The username comes from validated Auth Shell evidence,
with a generic Signed in label while unavailable. Menu links bind fresh
Auth evidence to issuer, client, subject, grant and local session context.
The menu excludes Continuum itself, drops stale or invalid responses,
and honors the independent expiry of authorization evidence. The public
page has no account trigger until a local authenticated session exists.

Production enablement requires the approved host-specific confidential
registrations in protected `CONTINUUM_AUTH_REGISTRATIONS` configuration.
Each host entry contains `client_id`, `client_secret` and an optional
approved `required_acr`. Missing configuration leaves its routes disabled
and its landing public. The three exact callback paths are
`https://<host>/auth/callback`. Auth must confirm its registered entry and
requester mapping for each host, including how three host-local client IDs
map to the single canonical `continuum` registry ID. Its v1 mapping has one
client ID per registry entry. There is no evidence that all three host-local
clients can be authorized Shell evidence requesters under that mapping.
An Auth-approved multi-host registration or explicit issuer-side mapping
design is required; a local environment variable cannot settle it.

Provision an application-readable, verifier-owned local cache at
`CONTINUUM_SHELL_REGISTRY`. Run Infrastructure's reviewed
`bin/application-shell-registry --cache <path>` under its authorized
verifier identity. The application reads the atomic verified bytes locally
and has no write access to the cache or signed pointer. Preserve the
verified cache across releases. Run the additive Continuum migration
before enabling any registration; rollback can retain these tables.
Never include credentials or a production session dump in release evidence.

## Requested Infrastructure decisions

1. Approve or decline the owner-requested anonymous header for
   Network, Library, and Intelligence with only the wordmark and the
   three public section links. If approved, identify the signed v1.3.0
   scope and SH-02 replacement evidence for a deliberate, Auth-owned
   entry to the local `/login`. Preserve anonymous `/`. Confirm whether
   the Auth v0.5.0 authenticated introspection username evidence meets
   the signed SH-05 verified username requirement.
2. Determine the signed v1.3.0 production disposition for Library and
   Intelligence footer text. Consider whether a reviewed, version-scoped
   compatibility approval can cover the requalified crops. Keep focus
   indicators, foreground on other roles and unmeasured states outside
   the text scope. [Infrastructure PR #20](https://github.com/harvj/infrastructure/pull/20)
   remains approval-only for v2 and cannot satisfy production preflight.

The first Infrastructure review thread was busy. Both requests were delivered
to the existing Infrastructure Application Shell specification review thread
for a decision. No Infrastructure or Auth settings, fixtures, deployments or
publication pointers were changed.

Infrastructure confirmed that this requires a forward signed, scoped SH-02
exception covering the three anonymous roots and the deliberate Auth-owned
entry through each host's `/login`. Test public rendering with a warm cache
and verify the exact callback and host-local session on that entry. It also
confirmed that v0.5.0 introspection evidence can satisfy SH-05 when it is
bound to the verified session and the real provider claim is observed.
The generic fallback label by itself cannot satisfy SH-05. For SH-06,
Infrastructure prefers a traceable accessibility treatment or a new signed,
narrow text exception after exact-candidate remeasurement. The owner wants
the current artistic styling preserved. The signed scope decisions remain open.

## Exact candidate verification

Candidate `673980114997dfcad7fd81ff9f1a474fcdb052f6` was tested from an
archive with SHA-256
`3719264feeddf76596a8b1e4d21f559a5d856cf41ee1876b4edb0c36ec2f244a`.

- Rails with disposable PostgreSQL and verified v1 and v2 fixtures passed
  23 tests, 506 assertions. The tests cover signed ID token validation,
  browser-bound state, callback replay, secure host-local cookie behavior,
  grant binding, stale context, expiry, revocation, provider outage,
  CSRF-protected logout, and registry retention on tamper or replay. Four
  tracked inventory tests also passed.
- Local HTTPS Brave journeys used the exact Rails app and a disposable
  provider transport fixture at 1440 × 900 and 390 × 844 on all three hosts.
  Anonymous root, deliberate authorization, username, ordered destinations,
  keyboard dismissal and focus return, delayed-response suppression and
  logout passed. The published Auth code informed this fixture. Real
  registered Auth journeys remain to be tested.
- Infrastructure's verifier fetched and installed a signed v1.3.0 runtime
  cache in a temporary directory. The browser used this snapshot. Registry
  replacement and malformed snapshot retention were tested locally.
- Anonymous browser checks covered all five signed fixture widths, existing
  Site Art variants, Network appearance and decode fallback. The Rails
  suite covers digest-addressed favicon delivery and host separation.
- Library sampled footer / credit at 2.8144:1 / 4.5020:1 on desktop and
  2.0292:1 / 4.0418:1 on mobile. Intelligence sampled 2.8252:1 / 2.5010:1 on
  desktop and 2.8476:1 / 2.4961:1 on mobile. All Network text samples
  passed. The visual Intelligence focus bands measured 17.7563:1 against
  each other at both widths. The credit link remained reachable with a
  visible outline in normal colors, forced colors and decode fallback.
  Below-target readings remain unresolved on this candidate. The prior
  approvals remain pinned to their own reference scope.
- The running local process retained its v0.2.0 label after moving the
  activation pointer. A new boot of the prior artifact displayed v0.1.2
  on all three hosts and passed readiness against the disposable database
  with the additive Auth tables retained. The v0.1.2 tag verified against
  `7c2d9cb797d0340b590ffa8439df607126bd18df`.
- The actual signed v1.3.0 preflight exited 1 for the full candidate SHA.
  SH-02 and SH-06 await Infrastructure's signed decisions. SH-03, SH-04 and
  SH-05 await approved Auth requester registrations and real browser
  journeys. SH-09 awaits Continuum operator qualification of the
  production-owned verifier and persistent refresh path. Existing
  signature, fixture and current pointer requirements remain in force.
