# Continuum confidential-client onboarding

**Disposition (2026-11-23) — routes and registrations remain inactive.**
The held release is
`079fdcc83536390b075e8bf722c9d97d5fece8b2`, archive SHA-256
`967b204ed0a9e3d6bf388ae54198b792a17eebecc18799bee4f5ce46764e885e`.

## Approved initial access

The owner specified **verified owner only, password sufficient, MFA
optional** on all three hosts. The Auth operation must use the independently
verified owner account from its protected workflow. Keep the member UUID
and credentials within that workflow.

| Confidential client | Exact callback | Auth Shell identity |
| --- | --- | --- |
| Library | `https://library.harvj.com/auth/callback` | Canonical destination and requester, `continuum` |
| Network | `https://network.harvj.com/auth/callback` | Separate requester under `continuum` |
| Intelligence | `https://intelligence.harvj.com/auth/callback` | Separate requester under `continuum` |

Each host initiates deliberate login at its own `/login` and establishes
its own session. The established delivery broker provides separate
credentials to protected files. The Continuum environment combines
them only under the reviewed protected handoff. Configure the consumer
to accept either verified password or stronger assurance as permitted
by the eventual approved issuer policy. An exact `required_acr` pin to
password would reject an MFA-authenticated result. Keep Auth's
administrator TOTP requirement and existing clients intact.

## Live verification and blocker

- Auth v0.5.0 is live at
  `36f2a27e4ddfee482734da80b1303aface1ef71c` with grouped requester
  support. Auth verified that none of the three callbacks, protected
  provisioning profiles, or canonical/requester mappings exists yet.
  The installed broker is active and its Add Application operation
  requires an administrator session with fresh TOTP. That requirement
  is separate from the owner's sign-in assurance for using Continuum.
- The per-client protected profile can choose `mfa_optional` for more
  than one client. The historical `AUTH_REMOTE_GAMING_CLIENT_ID`
  shortcut names a single client and remains untouched. The issue is
  the deployed `lib/rodauth_policy.rb#enforce_client_assurance` behavior:
  an enrolled account must complete second factor under
  `mfa_optional`. Native sign-in also retains existing enrollment
  requirements. Current options cannot establish that password alone
  is sufficient for the enrolled owner on the requested clients.
- Auth verified one eligible, attested owner with MFA enrolled. Its local
  candidate `8820ca10c286abdbc4838fa990f0ff1f98fa907a` implements
  `password_sufficient` for approved confidential first-party OpenID
  requests with S256 PKCE. Auth reported 204 passing specs and 28 Chrome
  examples, with RuboCop and dependency audit clean. Tests cover password sign-in for an enrolled
  user on all three clients, existing native and administrator MFA, and
  the achieved assurance claim for a session that completed MFA. Exact-SHA
  acceptance and protected release evidence remain pending in
  [Auth PR #14](https://github.com/harvj/auth/pull/14). Its hosted PR check
  runs on a test merge with the same tree as the exact head. Keep its
  evidence distinct from checks that explicitly ran on the head SHA.

## Activation evidence

Trusted verification accepted signed Shell v2.1.0 manifest
`5f1b26c7e0cc2d81d4f18c91d2a7eccb6e41de8ecab9af81d597c8555262e930`.
The mandatory global baseline remains v1.3.0. Both Continuum
dispositions are present. CT-02 binds the held candidate and its exact
archive. CT-01 requires deliberate White Sands entry and verified OIDC
return on each host, with separate local sessions. The baseline
fixtures and canonical registry entries remain identical to the
previously verified v2 inputs.

Exact selected preflight passed the scoped CT-02 observation and
exited 1 with CT-01 and the real Auth observations outstanding.
The older v0.1.2 release remains live and all three public `/login`
routes return 404. Infrastructure prepared the three-origin guarded staging review for this
archive. The prior [Infrastructure ingress decision](https://github.com/harvj/infrastructure/pull/2#issuecomment-7064754985)
and [Auth callback decision](https://github.com/harvj/auth/pull/5#issuecomment-7064744287)
describe the Muzeum precedent. The Continuum run requires its own approved
loopback-only ingress, issuer policy, three exact registrations and
operator preview. The browser must verify the staged artifact on all
three canonical origins, with public DNS and the serving release untouched,
before beginning any Auth journey. Preserve canonical TLS,
literal callback URLs, an isolated session store and the established
confidential handoff. Verify password-only entry, MFA when elected,
username, grant changes, logout and revocation. Auth-owned discovery
links follow route verification. Public activation follows signed
preflight. The commissioned registry cache requires no reinstall.
