# Continuum unified authentication

Continuum establishes one Rails session from a deliberate login on any
of its three canonical hostnames. The shared PostgreSQL record owns one
verified identity, one expiry and one Auth access grant. Each hostname
gets a distinct opaque host-only cookie. The originating confidential
client alone exchanges, introspects and revokes the grant. Existing Auth
registrations, callback URLs, credential profiles and administrator MFA
are unchanged by this application change.

## Cookie and application boundary

A Domain=harvj.com cookie would go to unrelated sibling servers as well
as Continuum. Secure protects transport and HttpOnly protects against
browser script reads. Neither prevents a sibling server from receiving or
attempting to replace a parent-domain cookie. SameSite treats sibling
origins on this domain as the same site. A wider cookie would therefore
expand exposure and fixation risk without supplying cross-origin CSRF
protection.

Continuum uses distinct Secure, HttpOnly, SameSite=Lax, Path=/ cookies
with the __Host- prefix and no Domain attribute. The server looks up
each session handle with its exact canonical host. An unrelated sibling
server receives no Continuum cookie and cannot set the required host-only
cookie on a Continuum host.

## Initial browser handoff

The initiating host creates the existing state, nonce and PKCE attempt
with its own attempt cookie. Two exact cross-origin POSTs seed independent
short-lived receiver cookies before the authorization redirect. A
successful, verified OIDC callback creates the shared, initially inactive
session. Two further exact cross-origin POSTs redeem short-lived opaque
tickets with the corresponding receiver cookie. A ticket is single-use,
bound to the expected predecessor origin and recipient host, and accepted
only with the pre-seeded receiver cookie. Ticket bodies and rendered
handoff pages are filtered and not cached. They stay out of URLs. The
handoff pages allow submission only to the next exact origin and cannot
be framed. Session handles use fresh random values and the session becomes
active only on successful final redemption.

Subsequent public roots perform no browser handoff or OIDC redirect.
They render the verified session when the matching handle is present.
Retries or interrupted handoffs require another deliberate login.
Unused preparation records and inactive sessions expire. Authenticated
lookups use the originating client and the original grant deadline.
A true grant invalidation or logout removes the common record and
cascades to each handle. CSRF protection remains in force for logout.
The first successful delete owns the Auth revocation call. During an
issuer outage the browser handles still become invalid immediately, and
the issuer grant remains bounded by its existing short expiry.

## Qualification boundary

The signed CT-01 disposition for the earlier release requires separate
sessions. The unified candidate needs a forward Continuum-only signed
disposition and an exact CT-02 rebind. The global mandatory Shell
baseline remains unchanged. Disposable browser and database tests are
required before repeating the three owner-only White Sands journeys on
canonical TLS. Verify entry from every host, direct sibling landings,
fresh grant filtering, single logout and original-client revocation,
replay, CSRF, expiry and rollback. Application rollback can retain the
additive tables and columns.
