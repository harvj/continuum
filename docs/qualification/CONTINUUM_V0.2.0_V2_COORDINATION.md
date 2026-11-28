# Continuum v0.2.0 signed v2 coordination

**Disposition (2026-11-23) — deployment blocked.** The reconciled local
release branch `release/continuum-v0.2.0` points at
`079fdcc83536390b075e8bf722c9d97d5fece8b2`. Its exact Git archive SHA-256
is `967b204ed0a9e3d6bf388ae54198b792a17eebecc18799bee4f5ce46764e885e`.
It includes remote main `092b9c14bffa41d87b9c0847bcda12a777f8f72a` and
preserves the previously qualified application runtime, navigation and
Site Art bytes. The separate release branch leaves unrelated work in the
main checkout intact.

## Exact candidate evidence

- Frozen Bundler and the PostgreSQL Rails suite passed. There were 26 tests,
  697 assertions, and no skips with verified v1 and v2 inputs. The signed
  registry lifecycle test passed with the merged Infrastructure verifier.
- In a disposable signed store, the exact archive booted as
  `v0.2.0-rc.1` on all three hosts. Independent fixture-key attestations
  promoted all three footers to `v0.2.0` in the same Rails process. Restart
  retained that value. The development artifact showed `v0.2.0-dev`.
  The signed fixture suite covers failed-evidence retention and rollback.
- Published Continuum Site Art records matched the verified browser input.
  Brave passed anonymous layout, Network appearance and decode fallback.
  At 1440 × 900 and 390 × 844, respective Library footer/credit minima were
  2.8144:1 / 4.5020:1 and 2.0292:1 / 4.0418:1. Intelligence minima were
  2.8252:1 / 2.5010:1 and 2.8476:1 / 2.4961:1. The Intelligence focus
  bands measured 17.7563:1 against each other at both sizes. Keyboard focus
  passed in normal colors, forced colors, and image fallback. These
  measurements were sent directly to Infrastructure for the exact archive.
- The commissioned cache was read successfully as the Continuum Unix user,
  which lacked write access. The timer was enabled and active, and the
  latest refresh succeeded. The root-owned 0644 projection held verified
  v1.3.0 sequence 46. Its applications and their order matched the verified
  v2.0.0 registry. The existing verifier remains the sole registry authority.
- The reviewed selector at Infrastructure
  `5de83984963104339085be026fb849c8d9bff85e` independently verified the
  selected v2.0.0 bundle and mandatory v1.3.0. v2 manifest SHA-256:
  `0f564d284b70ea547f28168df15a7ef59692ca24d0d3775d15947b0723dd898e`.
  Fixtures SHA-256:
  `8efa16791c0af1f3a96047d7d4180ac3607b333ba34bef2acc1dfcebd8bfb944`.
  The exact deployment preflight exited 1 for SH-02, SH-03/04/05,
  SH-06 and incomplete SH-10 evidence. The reviewed local CI checker ran
  the exact SH-07 vectors and refused to emit a complete deployment
  review with the other evidence outstanding.

## Protected decisions still outstanding

**Auth.** The Auth owner agent reverified [PR #12](https://github.com/harvj/auth/pull/12),
head `e08ede7361e9548f2d326904963b9d906ec355d3`, hosted CI and the
[owner assurance decision](https://github.com/harvj/auth/pull/12#issuecomment-7110051320).
Both hosted CI checks passed. The assurance comment distinguishes owner
authorization from independent review. Auth's deployment requirements
still require independent security review. The owner agent found no
eligible independent reviewer in the visible repository channels.
That gate holds merge and protected activation, registration, and real
White Sands verification. Disposable browser evidence does not stand
in for production Auth evidence.

**Infrastructure.** The Infrastructure owner agent confirmed the signed
v2.0.0 manifest has an empty Continuum exception scope. The merged
selector has no supplemental exception input that can add entries to
that immutable policy. The agent prepared an unsigned, local forward
v2.1.0 draft at `26ca8211ce98c493a45ee758700a028424562ac5`, bound to the
reconciled source, archive and crop evidence. The draft needs independent
policy and fixture review, trusted signing and publication, and approval
to select the forward version for Continuum. The published v2.0.0 bundle
and global v1.3.0 minimum are unchanged. No v1.4 policy was used.

Production remains v0.1.2 at
`7c2d9cb797d0340b590ffa8439df607126bd18df`. The read-only baseline
showed the neighboring Auth, Muzeum, Remote Gaming, Continuum Engine
dashboard and Arkham services active with their expected public HTTP
responses. The work stopped before pushing or activating Continuum.
No v0.2.0 tag or release exists.
