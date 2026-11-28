# Continuum v0.2.0 release readiness

**Disposition (2026-11-22) — blocked by signed production preflight.**

- Candidate `962a52dfe85129e86aaef43c46ad6727eca736d7`.
  SHA-256 of the tested Git archive
  `601643342ecde0d6ecf8a384933f6d2e47cf242539389047ed1d464cf8f67e20`.
- The latest published tag is v0.1.2. The new public Network appearance
  feature warrants a minor release. See the [draft v0.2.0 notes](../RELEASE_v0.2.0.md).
- Published v0.1.2 tag resolves to
  `7c2d9cb797d0340b590ffa8439df607126bd18df`. Public Network, Library and
  Intelligence each returned HTTPS 200 for `/`, `/up`, and `/ready`,
  and each displayed v0.1.2. The candidate remains local.

## Infrastructure approval review

[Infrastructure PR #20](https://github.com/harvj/infrastructure/pull/20)
proposes exactly `6f029a3117f0de6aa55757febe8242fa8498550c`, whose two
classifier tests and both GitHub CI checks passed. This is the supplemental
Shell v2 qualification approval for only the two specified anonymous footer
text crops, including the credit text. The PR excludes signed fixtures and
publication controls. A merge attempt was rejected by automatic approval
review because the PR lacked an independently recorded review. The PR is open.
An independent Infrastructure reviewer must record approval before merge.
There is no merge SHA.

## Intelligence credit focus and text measurements

Reproduced the weak single-color outline from the earlier approved
`f9158292fdc8d4fb5edc0bfa8d331f90ccb5292b` archive at 1440 × 900 and
390 × 844. Most sampled solid focus pixels fell below 3:1 against the same
pixels before focus. The candidate uses a 2px dark inner ring and adjacent
2px white outline on keyboard focus of the Intelligence footer link only.
The adjacent rendered bands measure **17.7563:1** against each other at both
viewports. This is the contrast between bands, separate from pixel contrast
against the artwork. Forced colors uses the system highlight outline.

Verified that Tab reached the link, the accessibility tree exposed **Jim
Harvey**, and the target was `https://harvj.com/`. Verified the visible focus
indicator at both viewports in normal colors, forced colors and image-decode
fallback. Typography, unfocused colors, image bytes and crop are unchanged.

The supplemental approvals still cover their original reference scope in the
[v2 qualification report](APPLICATION_SHELL_V2.md). The focus CSS changes the
approved stylesheet fingerprint. The version string also moves the centered
credit's sample position by about 2.23 CSS px. Measurements on the new archive
therefore require requalification. The published Site Art snapshot
`f9ef3c97194705a80c9ef26c3a57ed6e3ee6af969255b283cd73c6a62fcfebfd`
still matches every tested Continuum record.

| Surface | Viewport | Footer text | Credit text | New candidate disposition |
| --- | --- | ---: | ---: | --- |
| Network light | 1440 × 900 | 6.6877:1 | 6.2707:1 | Both `pass` |
| Network light | 390 × 844 | 6.0982:1 | 5.0377:1 | Both `pass` |
| Network dark | 1440 × 900 | 17.1026:1 | 17.4948:1 | Both `pass` |
| Network dark | 390 × 844 | 16.7580:1 | 16.5371:1 | Both `pass` |
| Library | 1440 × 900 | 2.8144:1 | 4.5020:1 | Footer `unresolved`, credit `pass` |
| Library | 390 × 844 | 2.0292:1 | 4.0418:1 | Both `unresolved` |
| Intelligence | 1440 × 900 | 2.8252:1 | 2.5010:1 | Both `unresolved` |
| Intelligence | 390 × 844 | 2.8476:1 | 2.4961:1 | Both `unresolved` |

The Library mobile credit also fell below the earlier approved 4.0784:1
minimum. No approval IDs were carried onto this new archive. No exception
was applied to focus.

## Tests and release gate

- The exact candidate passed 16 Rails tests with PostgreSQL and the verified
  v1/v2 fixture inputs (364 assertions), four inventory tests, and JavaScript
  syntax checking.
- Brave Chromium 158.0.8127.42 exercised all three candidate landing pages at
  the five signed fixture widths. Network appearance passed, including
  system preference, persistence, keyboard, touch and decode fallback.
  Library and Intelligence hide the appearance control. The Rails suite
  covers favicon delivery, anonymous navigation, readiness and host isolation.
- The disposable rollback kept v0.2.0 in the running process after changing
  the release pointer. The next boot under the prior artifact displayed
  v0.1.2. The existing v0.1.2 tag binding verified.
- The installed `application-shell-preflight --review` command verified the
  signed v1.3.0 baseline, found no signed Continuum exceptions, and exited 1
  for the exact candidate. SH-02, SH-03, SH-04, SH-05 and SH-09 blocked on
  missing Auth and runtime registry behavior. SH-06 blocked on the
  below-target Library and Intelligence footer contrast. The supplemental
  v2 records cannot satisfy this production gate.
- The release stopped before the Continuum push, remote CI, staging,
  activation, or GitHub release. No production rollback was needed.

A subsequent release requires a passing candidate-bound production preflight
under the existing published policy. A revised applicability disposition must
come through the authorized Infrastructure process. The optional v2
SH-05/Auth and SH-07 exact-artifact publication work stay on the
[roadmap](../ROADMAP.md#p15--application-shell-readiness-and-auth-onboarding).
