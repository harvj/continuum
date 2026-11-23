# Application Shell v2.0.0 qualification

**Disposition (2026-11-22)** — Partial qualification. The local Continuum
candidate is `f9158292fdc8d4fb5edc0bfa8d331f90ccb5292b`. The
`git archive --format=tar.gz` used for testing had SHA-256
`242bf4b100f42a6cc2fa367809433cf04ae9038d3508620571bd775150cca006`.
This is qualification evidence, separate from production preflight records.
The candidate was neither pushed nor deployed.

## Verified inputs

| Input | SHA-256 |
| --- | --- |
| v2.0.0 manifest | `0f564d284b70ea547f28168df15a7ef59692ca24d0d3775d15947b0723dd898e` |
| v2.0.0 conformance fixtures | `8efa16791c0af1f3a96047d7d4180ac3607b333ba34bef2acc1dfcebd8bfb944` |
| v2.0.0 registry | `fc62e66b0b34ff2d2e2da3ac96797059068b1573562b8ec8007f0dbd5508227b` |
| Current v1.3.0 manifest | `dd810b8879c71a206af652885cce5c84cb10022dfa3ae9480ed66dc73580771b` |
| Current v1.3.0 conformance fixtures | `321234fa59f2110e94e47896e22c82a0f03b635cf477762b41329630fb1acd78` |
| Current v1.3.0 registry | `06f064e98025a06d195c76654fade82f5976aa2c1b946fb600052098814b360e` |

Ran `bin/application-shell-version --version 2.0.0 --output <new-directory>`
from an archive of Infrastructure
`84b631269fea351e146fc01babe9bcbb12edb283`. Its pinned Ed25519 verifier
accepted the detached signature and verified every manifest-bound payload.
The expected manifest and fixture digests matched exactly. The versioned
v1.3.0 signature endpoint returned 404, so v1.3.0 was verified through its
signed current pointer and all manifest-bound files. The existing
`application-shell-preflight --app continuum --revision <candidate> --describe`
returned v1.3.0, `shell-v1`, registry schema 1, and no Continuum exceptions.
No production review or approval was produced.

For the separate footer text qualification, pinned Infrastructure approval
revision `6f029a3117f0de6aa55757febe8242fa8498550c` on local review branch
`codex/continuum-footer-contrast`. The record and definitions are in
`docs/qualification/continuum-footer-contrast.md` and
`docs/qualification/continuum-footer-contrast.json` at that revision.
The JSON SHA-256 is
`158b355424ecde968afcd0205df075fa67d52f90cc8560c1ce425ab3890d0a46`.
At qualification time GitHub had no review branch or PR for this commit.
Use this exact local Git object for review handoff. Remote review
availability remains pending authorized publication by Infrastructure.
The two IDs are application qualification approvals, separate from the
signed exception registry and production preflight.

The verified local Site Art build from `9dc3c2df720c31be90ef52258d00d475fabc581a`
matched the published Continuum records and artwork digests in release
`f9ef3c97194705a80c9ef26c3a57ed6e3ee6af969255b283cd73c6a62fcfebfd`.

## Auth inventory

| Capability | Continuum source finding |
| --- | --- |
| OIDC integration with `auth.harvj.com` | Absent. Host-scoped routes in `config/routes.rb` expose the public landing and artwork; there is no client, login entry, callback, or token validation. |
| Authenticated application session | Absent. The landing controller reads the artwork snapshot and section only. Rails session facilities do not establish an Auth-backed session. |
| Grants and navigation authorization | Absent. Network, Library, and Intelligence links are public and rendered from the section list. There is no application switcher or grant client. |
| Verified username or account disclosure | Absent. No identity or username is rendered. |
| Login, logout, and session invalidation | Absent. The Home icon links out to `auth.harvj.com`; that navigation does not sign a visitor into Continuum. |
| Shell identity or grant handling | Absent. There is no binding between a local identity and an Auth grant result, and no signed registry runtime. |

Reviewed [Continuum PR #1](https://github.com/harvj/continuum/pull/1)
at `cc8fddf730d70099f8e3b18955e52e339e3fce3d`. It adds a linked footer
credit and calendar-year rollover across the three public hosts, while
retaining the boot-resolved version. The qualification candidate incorporates
that behavior with separate wrapping groups. PR #1 leaves Auth onboarding,
the shared CI adapter and deployment evidence as follow-up work.

**SH-05 is not applicable to the current public-only experience.** Session
replacement, expiry, delayed grants, restoration, revocation and genuine
invalidation belong to the future registered Auth integration. The signed
reference tests exercise the vectors, and they provide no evidence of a
Continuum authenticated implementation.

## Application results

Tested anonymous `/` on Network, Library, and Intelligence. Local Rails
tests also covered background and favicon routes, liveness, readiness and
host isolation. The browser used Brave Chromium 158.0.8127.42 over loopback
with Rails-rendered pages and the exact candidate's static assets.

| Check | Disposition and evidence |
| --- | --- |
| SH-01 layout | Pass for measured anonymous geometry at 1440, 701, 700, 390 and 320 CSS px on all three hosts. Desktop inset was 6.5vw with wordmark top 34.98px; mobile inset was 28px with wordmark top 26.98px. Navigation targets were at least 44px with no horizontal overflow. The header is in document flow and scrolled away on a long-page probe. Signed-in/disclosure cases remain outside this experience. |
| SH-02 public entry | Public links and anonymous access pass. Local Log In and its Auth journey are missing for full adoption. |
| SH-03 signed-in disclosure | Not applicable on these public routes. No account disclosure, settings or logout exists. |
| SH-04 registry | Both verified registries match the signed fixture order and map `continuum` to `Library` at its canonical URL. On all three hosts only the public Library link is rendered from those destinations. The authenticated ordering, omission and grant vectors require a registered consumer. |
| SH-05 session and grants | Not applicable. See the Auth inventory. No formal v1 exception was assumed or claimed. |
| SH-06 appearance and artwork | Anonymous Network pair behavior and sampled text contrast pass. Library and Intelligence correctly hide the control. Their scoped below-target footer and credit text have `approved_exception` results. Credit focus visibility passed in the tested states, and outline contrast remains a separate check. |
| SH-07 footer and release identity | Calendar year rollover, credit link, wrapping and the packaged `VERSION` baseline pass. The v2 immutable RC and receipt lifecycle is missing. See the release probes below. |
| SH-08 scope and rollback | Exercised all three public landing hosts with the same candidate and existing host boundaries. The rollback probe was local. Production adoption evidence remains a separate review. |
| SH-09 runtime registry | Missing for full adoption. Anonymous rendering is local and contains no protected switcher links. Runtime refresh and last-verified registry persistence require an application adapter. |
| SH-10 gate | Signed current discovery succeeds for the exact candidate. The existing manual v1.3.0 preflight remains in force. No v2 enforcement or new production review was attempted. |

### Appearance and contrast

Network uses `continuum.network_background_light` and
`continuum.network_background_dark`. Library and Intelligence each have one
approved background. Verified mode/asset/foreground pairing, live system changes
until explicit selection, stored overrides, reload and navigation persistence,
single/incomplete-pair suppression and selection restoration on returning to a
pair. The 44px trigger measured 12px from the viewport edges, and followed
emulated right/bottom safe areas of 24px/30px. Touch opening and selection at
320 × 240, keyboard opening and Escape focus return passed. The open panel
cleared the footer credit on that short viewport. A failed switch
kept the previous complete treatment; a failed initial decode kept the neutral
theme and the stored preference. The forced-colors test suppressed the artwork.
A signed-in appearance test requires the future Auth integration.

### Scoped footer contrast dispositions

Remeasured the exact candidate archive in Brave Chromium 158.0.8127.42 using
the verified Site Art records. Compared matched screenshots with and without
text paint at solid foreground pixels, retaining the resolved glyph shadow
where present. Samples inside the credit link bounds were measured separately
from ordinary footer text. The seven approved presentation file fingerprints,
asset digest and presentation record matched. See the
[machine-readable measurements](APPLICATION_SHELL_V2_FOOTER_RESULTS.json)
for browser capture hashes and per-element outcomes.

| Host and mode | Viewport | Footer text | Jim Harvey link | Text result for both |
| --- | --- | ---: | ---: | --- |
| Network light | 1440 × 900 | 6.6877:1 | 5.0150:1 | `pass` |
| Network light | 390 × 844 | 6.4557:1 | 4.5488:1 | `pass` |
| Network dark | 1440 × 900 | 17.3166:1 | 17.4703:1 | `pass` |
| Network dark | 390 × 844 | 16.8704:1 | 16.1257:1 | `pass` |
| Library | 1440 × 900 | 2.6562:1 | 4.3644:1 | `approved_exception` · `continuum-library-footer-contrast` |
| Library | 390 × 844 | 2.0292:1 | 4.0784:1 | `approved_exception` · `continuum-library-footer-contrast` |
| Intelligence | 1440 × 900 | 2.6802:1 | 2.3931:1 | `approved_exception` · `continuum-intelligence-footer-contrast` |
| Intelligence | 390 × 844 | 2.7450:1 | 2.3473:1 | `approved_exception` · `continuum-intelligence-footer-contrast` |

The reference classifier yielded eight `pass` and eight
`approved_exception` element measurements. It returns `unresolved` for
below-target results outside the exact approval or below the approved
per-element minimum at four-decimal precision, and when retained checks fail.
The approvals apply only to these two anonymous `/` bottom-role normal-color
crops after the approved image loads. Network, headers, navigation, menus,
article content, other controls, unmeasured viewports, forced colors and
fallback remain subject to the ordinary checks. Prior sampled header contrast
remains above target at both crops on all three hosts.

On Library and Intelligence at both crops, Tab reached the native link to
`https://harvj.com/`. The accessibility tree exposed a link named **Jim
Harvey**. The visible credit was underlined and an identifiable 2 CSS px
solid outline appeared on keyboard focus in normal colors, forced colors,
and image-decode fallback. The normal-color outline on Intelligence has low
contrast along much of its perimeter. Outline contrast remains `unresolved`
as a separate numerical check and carries no approval ID. A visible focus
indicator and these text dispositions do not establish WCAG conformance.

Requalify after material changes to artwork, crop, effective foreground or
shadow, typography, markup, or accessibility behavior. Requalification also
applies when effects change without changing the fingerprints listed by
Infrastructure. New below-target crops, or readings worse than the approved
minima, require separate review. Results at or above 4.5:1 are passes.

### Release identity probes

The candidate archive rendered `Continuum v0.1.2` on all hosts. In a disposable
release tree, switching `current` to archived v0.1.1 left the running process's
three labels on v0.1.2. A fresh boot through the new target used v0.1.1. The
existing exact-tag verifier and archive and rollback regression tests passed.

The signed SH-07 fixture defines development, numbered candidate, acceptance
and publication records and a same-process transition sequence. Continuum
currently reads only the packaged `VERSION`; it has no allocator for immutable
candidate numbers, launch binding for an artifact digest, authenticated
acceptance/publication verifier, or local publication receipt store. The
qualification archive's captured SHA-256 binds this test run, but does not
establish a runtime release identity. Same-process promotion, durable
failed-evidence retention, and v2 published/candidate rollback cannot pass
until those mechanisms exist. The existing deployed-version behavior was
preserved.

## Reproduction and next milestone

Save the verified bundles as `v1/` and `v2/` under a separate qualification
input directory. Run the regular tests from the exact candidate and set
`SHELL_QUALIFICATION_INPUTS` to that directory to run the additional signed
fixture checks. The Rails tests recheck the pinned fixture and registry
digests before exercising applicable cases. The candidate ran 16 Rails tests
with disposable PostgreSQL and 364 assertions, plus four tracked inventory
tests. The reviewed Infrastructure reference suite ran 47 tests with one
skip; its fixture bytes matched the signed v2 fixture. Reference results
are separate from the application results above. The footer adoption reran
16 Rails tests with disposable PostgreSQL, 364 assertions, and no skips.
Both Infrastructure classifier tests passed.

Recommend [P1.5 — Application Shell readiness and Auth onboarding](../ROADMAP.md#p15--application-shell-readiness-and-auth-onboarding).
Implement the artifact and publication workflow in disposable releases,
address remaining accessibility contrast, and coordinate Auth registration and grant
handling with the future editorial and Network requirements. Run full
candidate-bound verification again before proposing v2 adoption.
