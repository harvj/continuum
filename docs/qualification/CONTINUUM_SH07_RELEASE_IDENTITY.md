# Continuum SH-07 exact-artifact release identity

**Disposition (2026-11-23) — SH-07 implementation qualified locally.**
Source candidate `5fa9efe1afe42907c11bbf2152ebbbef376b9039` was packaged
with archive SHA-256
`e188f36ddf22a0b0dc79c93dda5abc9264d9c4698dc03a99e9f3547f4c07245c`.

The [release identity procedure](../VERSIONING.md#sh-07-exact-artifact-release-identity)
seals committed development and numbered RC identity. The authorized
importer verifies independent acceptance and publication attestations,
including the exact full source SHA and retained archive digest, and
records one signed final receipt for a version. The runtime reads local
evidence and keeps its own verified label across activation-pointer
movements. Legacy releases still read packaged `VERSION` at boot.
Navigation and Site Art selection, effects and assets were unchanged.

## Qualification evidence

- Reverified the detached signature and all manifest-bound files for
  v2.0.0 from reviewed Infrastructure revision
  `84b631269fea351e146fc01babe9bcbb12edb283`.
  Manifest SHA-256:
  `0f564d284b70ea547f28168df15a7ef59692ca24d0d3775d15947b0723dd898e`.
  Fixture SHA-256:
  `8efa16791c0af1f3a96047d7d4180ac3607b333ba34bef2acc1dfcebd8bfb944`.
- The exact archive passed 26 Rails tests with PostgreSQL and the signed
  fixtures (697 assertions), the registry lifecycle test and four
  inventory tests. The signed SH-07 sequence checks all three footers.
  The packaging integration separately exercises exact archive binding,
  version-scoped allocation and reuse, signatures, wrong-artifact and
  chronological rejection, conflicting evidence and candidate/published
  rollback.
- A running Rails process booted from the signed unpacked release displayed
  `v0.2.0-rc.1` on all three hosts and switched to `v0.2.0` after the
  separately signed disposable attestations were imported. The process ID
  stayed constant. Restart retained the published value, and the identical
  development archive booted as `v0.2.0-dev`.
- Production adoption still requires authorized release and evidence
  signers, reviewed secure installation and read-only runtime trust
  configuration under the actual deployment procedure. No production
  signature, acceptance, or publication was generated.

## Remaining production qualifications

| Check | Verified | Outstanding |
| --- | --- | --- |
| SH-05 | Existing Continuum tests verify bound claims and session behavior with a disposable provider. [Auth review #12](https://github.com/harvj/auth/pull/12) is still a draft. | Approved production requester mapping and registrations, then real White Sands journeys and observed username evidence. |
| SH-09 | The trusted verifier accepted signed v1.3.0 registry sequence 46. The [draft cache projection](https://github.com/harvj/infrastructure/pull/23) emitted identical private 0600 and app-readable 0644 bytes and retained its projection when refresh failed. Continuum read the ordered registry. The signed lifecycle suite passed locally. | Independent cache approval and installation, then verification with the production verifier and Continuum identities. The host has no Continuum cache unit. |
| SH-10 | Verified the immutable signed v2.0.0 qualification bundle independently. The installed trusted preflight discovered signed v1.3.0 and rejected v2 behavior and fixture evidence against it. | The authorized v2 preflight/adoption path and candidate-bound production evidence. Optional signed fixtures do not switch the current production gate. |

Continuum still runs v0.1.2 at
`7c2d9cb797d0340b590ffa8439df607126bd18df`. The signed current pointer and
Auth, registry and production configuration remained unchanged.
