# Continuum confidential-client onboarding

**Disposition (2026-11-24 UTC) — Continuum v0.2.0 deployed and published.**
The first protected qualification held the earlier
`079fdcc83536390b075e8bf722c9d97d5fece8b2` archive
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

## Live verification

### Unified candidate

The owner defined one Continuum application with three public entry
hosts and one sign-in and sign-out. Exact candidate
`3de4a58d7de5d2090ba6a81ea5b6813454bb44b2`, archive
`9a37977e17900bfa254fcc60a5720bc7c20f44569f8332f52e35db09a85d7cec`,
uses one shared PostgreSQL session and separate host-only handles rather
than a cookie sent to unrelated harvj.com applications. Pre-seeded
receiver nonces, exact predecessor origins and short, single-use
POST-body tickets bind the initial host handoff. Later direct roots
load without another OIDC redirect. The originating confidential client
owns grant evidence and revocation. No Auth registration was changed.

Local PostgreSQL qualification passed 29 tests and 990 assertions.
A disposable Brave run on the three canonical names with fixture TLS
and a simulated provider passed initial entry from each host, two
receiver handoffs, direct signed-in landings and shared logout.
[Hosted CI](https://github.com/harvj/continuum/actions/runs/45312050166)
passed on the exact SHA. The anonymous Rails output and 20 normal,
focus and fallback captures match the earlier candidate. Appearance
and forced-colors assertions also passed. Disposable SH-07 exercise
confirmed exact archive identity, same-process footer promotion and
restart retention. The deployed v0.1.2 artifact rendered all three
landings against the additive schema in a disposable rollback rehearsal.

Signed v2.1.0 preflight rejected CT-01 because it requires independent
host-local sessions and CT-02 because it binds a different archive.
Continuum and Infrastructure are reviewing the forward disposition in
[Infrastructure PR #27](https://github.com/harvj/infrastructure/pull/27).
Auth confirmed that the originating registration is the authorization
boundary. Full Continuum withdrawal uses the existing protected
membership and grant controls for all three registrations. Disabling
one registration stops entry there and invalidates grants it issued.

The approved exact [v2.3.0 publication receipt](https://github.com/harvj/infrastructure/pull/27#issuecomment-7120300685)
binds manifest SHA-256
`1812f3250085b6952169700443f14fede2fa2dd0b4bd3d756b33531a330698d5`.
The trusted selector verified it with adopted v2.0.0 and retained the
global v1.3.0 baseline.

Live unified preview `a5a1ab15de3db061b68a973faa298f32` verified
the exact archive over normal canonical TLS on all three hosts. Starting
from Network, Library and Intelligence respectively, the owner entered
once and all three roots then showed the verified username and same fresh
destinations on direct requests with no redirects. Each trial had only
one password-assurance originating exchange and no sibling exchanges,
MFA or refresh. The three Secure, HttpOnly host-only handles were distinct.
Keyboard-visible identity, artwork, favicons and authenticated mobile
layout passed. Logout on Library, Intelligence and Network respectively
made all three roots anonymous and revoked the sole originating grant
exactly once. The isolated units, browser, tunnel and fixture database
were removed. Public v0.1.2 and public routes remained unchanged.

The exact signed v2.3.0 preflight passed all required cases.
Review SHA-256 is
`2d4d0fc765956c5e5450805ef422355dabddc50f6b7722d510bcebbbf5c78314`.
The live read-only registry matched the signed applications and order,
at sequence 54.

The owner authorized a one-time Continuum-only encrypted off-host backup.
The operator verified and restored it in isolation, including all nine
v0.1.2 landing and health probes. The exact v2.3.0 preflight passed again
before migration and switch. The two additive authentication migrations
ran against only the Continuum database. The approved protected
environment and exact release were activated independently. The public
pointer now resolves to `3de4a58d7de5d2090ba6a81ea5b6813454bb44b2`.
All three hostnames passed HTTPS, readiness, anonymous navigation,
guarded login availability, Site Art, favicon and v0.2.0 footer checks.
Neighbor service process identities and representative HTTPS responses
matched their baseline. The backed-up prior environment and v0.1.2 tree
remain available for rollback with the additive schema retained.
Production browser acceptance passed over normal public DNS and TLS.
One Network password sign-in yielded a single Auth grant and no sibling
grants, MFA exchange or refresh. All three direct roots showed the same
verified username and fresh destinations with distinct host-only cookies.
Library logout cleared the shared session on all three roots and Auth
recorded one revocation of the Network grant with zero active grants.
No Auth or adjacent application config changed.

The [GitHub v0.2.0 release](https://github.com/harvj/continuum/releases/tag/v0.2.0)
points to the deployed SHA and provides the exact archive above. GitHub's
reported asset SHA-256 matches, and the
[release synchronization check](https://github.com/harvj/continuum/actions/runs/45317313723)
passed. The live footer remains in packaged-version mode. Exact SH-07
receipt promotion and rollback were qualified in a disposable store.

### Separate-session preview evidence

The first real White Sands preview completed on archive `967b204e…885e`.
The owner password-authenticated through Network and reused the Auth
session for Library and Intelligence. Each app remained anonymous until
its deliberate local entry, then showed the verified username and three
fresh destinations. Auth observed one password-assurance exchange per
host and zero MFA or refresh exchanges. All three host-local CSRF logout
forms returned the browser to anonymous, with sibling sessions surviving.
Auth recorded zero grant revocations. The signed v2.1.0 preflight passed
CT-01 and retained SH-03, SH-05, SH-06 and SH-10 as failed. Auth reproduced
the cause on its deployed revision with disposable credentials. The
form revocation request gets HTTP 403. Auth's JSON back channel revokes
the same confidential-client access grant.

The replacement candidate
`ca3169246d3c94725124a4553d602ae809948586` uses JSON for revocation
and keeps introspection form-encoded. Archive SHA-256 is
`d8f7a8dd50f265733e3dcb536b45b59ad6ae3076f5b51016ede15312e4d4d21e`.
It passed 27 Rails tests and 702 assertions with PostgreSQL and verified
fixture inputs, including the new transport regression.
[Hosted exact-SHA CI](https://github.com/harvj/continuum/actions/runs/45308903335)
also passed. Exact Rails anonymous renders and 20 ordinary/fallback
footer captures matched the original, and forced-colors and focus checks
passed.

The exact replacement passed real provider-side revocation in isolated run
`8c02fe4d22b9b13089a8812ab62c8952`. Auth recorded one password-assurance
exchange and one active grant per host before logout, then one revoked
grant, one revocation event and zero active grants per host after logout.
Each host returned to anonymous through its own CSRF-protected form.
Library remained signed in with fresh grants after Network logged out,
and Intelligence remained signed in with fresh grants after Library
logged out. No central logout was used.

Signed v2.1.0 CT-02 still names the earlier source and archive.
Infrastructure prepared a forward, unsigned v2.2 rebind for review.
The exact signed disposition remains outstanding. The owner requested
that Library and Intelligence display the username immediately when
visited after signing into Network. Signed CT-01 currently requires a
deliberate entry on each host and no silent OIDC on anonymous landings.
Cross-host sign-in on direct landing visits needs a reviewed policy and
Auth design before it can be qualified. Production remains at v0.1.2.

### Auth production handoff

Auth v0.5.0 at `3d13a0d565721d16632a7c068ac85594c002021a`
supersedes the registration-only checkpoint below. Its installed signed
v1.3.0 Auth preflight and hosted exact-head CI passed. The protected
planner installed Library's canonical binding and three host-local
requester mappings while preserving the registered callbacks, protected
handoffs and owner-only, password-sufficient policy. See the
[Auth production handoff](https://github.com/harvj/continuum/pull/1#issuecomment-7119015582).

The selected signed v2.1.0 preflight on the held Continuum archive
still exits 1 on CT-01, SH-02/03/04/05/06 and SH-10. CT-02 still passes.
CT-01 requires an observed White Sands callback and separate host-local
session on each of the three canonical HTTPS routes. Production remains
on v0.1.2. Infrastructure found a preview design but no installed preview
identity, launcher, isolated fixture database or running ingress at the
reviewed loopback ports. The current work is to validate a runnable
isolated preview and then observe the three real journeys.

[Hosted Continuum CI](https://github.com/harvj/continuum/actions/runs/45304821639)
passed on the exact candidate via a verification-only branch. The
signed v2.1.0 Shell CI audit passed SH-07 with 3 tests and 191 assertions
covering the immutable release identity, verified receipts, same-process
promotion, failure retention and rollback. The audit remained incomplete
for the other cases because its adapter ran SH-07 only. The production
preflight remains the activation gate.

Infrastructure passed a disposable target-host isolation rehearsal.
Caddy could connect to the preview Unix socket, an unrelated UID was
denied, both production PostgreSQL paths were blocked, and canonical
Auth and Site Art TLS worked. The rehearsal left no running listeners.
Infrastructure then staged and rehashed the exact candidate under a
private run directory. The preview process has not started. Automatic
approval review rejected creating the two dedicated no-login host
identities and staging temporary root-only Auth, session and ingress
material pending explicit authorization for those operations. The owner
subsequently authorized the Infrastructure and Continuum teams to run the
preview. Infrastructure started a timed isolated instance, and Continuum
verified the exact archive marker and anonymous landing via canonical TLS
in a disposable browser profile on all three hosts. The Auth observer
recorded a zero-grant baseline for the run. Real authentication requires
direct owner interaction in that browser.

### Registration-only checkpoint

Auth v0.5.0 at `3e39e9bc8236b48150137d2ed953cf65f31cef3d`
has three distinct, enabled confidential OpenID registrations with the
exact callbacks above and approved production `password_sufficient`
profiles for the same sole verified owner. Auth verified the three
root-owned mode-0600 handoffs by metadata. Credential values stay on the
protected host. Auth's canonical `continuum` mapping and two requester
aliases are still absent. The deployed Auth
`ApplicationCatalogue.validate_registrations!` requires a reviewed
canonical client with the catalogue name and public URL. The Library
client has the audited provisioning name and an unset public URL.
Auth owns reconciling this metadata while preserving the existing
credential, client identity and provisioning retry behavior.
Auth prepared exact local candidate
`9a7b72ad0015a751e35b15b7531be45dbe209aa1` for a protected
catalogue binding and reported 205 passing specs. Automatic approval
review rejected the requested Auth branch push and draft PR because
the reconciliation requires separate explicit authorization in that
workflow. The candidate is local and the deployed mapping is unchanged.
The public Continuum host routes still return
404 for `/login`; public roots and both health endpoints return 200.

The trusted selector verified Shell `--version 2.1.0 --adopted-version 2.0.0`
for the exact held artifact and retained the global v1.3.0 baseline.
CT-02 passed. CT-01 and SH-02/03/04/05/06/10 still require actual
White Sands journeys and grant evidence on the exact artifact. The
held candidate passed 26 Rails tests and 697 assertions against PostgreSQL
with the verified fixture inputs. Infrastructure verified the proposed
loopback ports, existing certificate coverage and in-place readability,
and the read-only registry projection. The isolated guarded preview
still requires an authorized launch and an owner browser session.
SH-07 passed the permitted isolated release identity vectors. Live
receipt promotion also requires the release store and authorized signer
roles described in [versioning](../VERSIONING.md).

## Earlier assurance investigation

- At the earlier checkpoint Auth v0.5.0 was live at
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
