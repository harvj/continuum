# Continuum v0.2.0 owner assurance and protected release gates

**Disposition (2026-11-23) — blocked by technical gates.** The held
Continuum candidate remains `079fdcc83536390b075e8bf722c9d97d5fece8b2`
on local `release/continuum-v0.2.0`, archive SHA-256
`967b204ed0a9e3d6bf388ae54198b792a17eebecc18799bee4f5ce46764e885e`.
The existing [exact-candidate measurements and test results](CONTINUUM_V0.2.0_V2_COORDINATION.md)
continue to apply.

## Auth assurance and the actual activation check

Auth traced the separate review requirement to `docs/deployment.md`, under
“Activation gates and recovery.” No GitHub rules were reported for the
PR #12 base. The owner authorized the candidate-specific alternative
in [the recorded assurance decision](https://github.com/harvj/auth/pull/12#issuecomment-7110051320).
Auth recorded it in the documentation-only
[Auth PR #13](https://github.com/harvj/auth/pull/13) at
`c72011ed4534d518609d493c1cf5b584eb15b249`. The policy record keeps the
accepted source `e08ede7361e9548f2d326904963b9d906ec355d3` unchanged and describes
owner assurance explicitly. No independent review was claimed or requested.

The exact-head hosted CI checks are green, and the Auth agent reproduced
28 passing Chrome examples from the sealed archive. The archive SHA-256
is `e70734faee0a11d0a84e5bbe80fb9380d1f3a317b8861588be238ef393a46ddc`.
The pinned Auth Shell checker at
`3e039ef2159c4aceb0271669357144744ac04920` ran against signed v1.3.0 and
rejected incomplete observed evidence. The controlling executable path
is the Capistrano task in `config/deploy.rb`, then the installed
`/usr/local/sbin/auth-service` coordinator, as documented in Auth's
`docs/integrations/auth-shell-p1.6-deployment.md`. Promotion requires
`/etc/auth/shell-reviews/<sha>/approval.json` binding the exact staged
archive and observed review digests, and passing live signed preflight.
The protected approval has no GitHub reviewer field. Exact-SHA CI and
owner acceptance keep their own distinct meanings.

Auth closed SH-07 and SH-09 on the literal archive in isolation. The checks
covered year rollover, the running version across pointer movement,
restart and a prior artifact rollback, plus a signed registry update in
a running browser and rejection of tampered, replayed or unavailable
updates. The updated observed-review SHA-256 is
`e872e8fc37aecf6f3387f31e933c2d978751363be04984fe6b4d8278ab7e2da6`.
The pinned checker still exited 1 for SH-01, SH-03, SH-04, SH-05,
SH-06, SH-08 and SH-10. In particular, the protected staged-tree approval
and production activation-stop evidence are absent. Real Auth registration
and the first protected browser journeys remain pending. Any eventual
metadata merge must keep the accepted head unchanged; Capistrano stages
the separately pinned `APPROVED_COMMIT`.


## Infrastructure approval and signing boundary

[Infrastructure PR #25](https://github.com/harvj/infrastructure/pull/25)
holds the forward v2.1.0 policy at
`26ca8211ce98c493a45ee758700a028424562ac5` against the exact published
v2.0.0 source. The checked draft has seven manifest-bound payloads and
manifest SHA-256
`5f1b26c7e0cc2d81d4f18c91d2a7eccb6e41de8ecab9af81d597c8555262e930`.
It contains candidate-bound Continuum anonymous-entry and footer text
scopes, retaining independent keyboard-focus verification.

The owner design decisions and Auth assurance are already recorded.
The remaining publication decision binds the exact Infrastructure manifest
above to authorized publication. The pinned publisher's detached Ed25519
signature is a separate technical prerequisite. Infrastructure's
`deploy/stage-application-shell-version` requires `manifest.json.sig`,
validates it with the installed publisher pins, checks the exact source and
digest, and refuses replacement of a published immutable version. The
ordinary renewal receiver can renew only the identical manifest, as
documented in `docs/p15-publication-renewal.md`. The isolated staging negative controls rejected both the missing
signature and a signature from an untrusted disposable key before
creating a version. The live v2.1.0
manifest endpoint is absent. The authorized custodian must sign and
publish this exact reviewed manifest through the immutable stage path.
Continuum's version selection remains v2.0.0 until that happens. The
mandatory global v1.3.0 pointer stays unchanged.

## Current production state

The actual selected v2.0.0 gate still has no Continuum exceptions. The
commissioned registry timer remains active with a successful refresh.
The Continuum identity can read its projection and lacks write access.
The production symlink remains on
`7c2d9cb797d0340b590ffa8439df607126bd18df`, and all three public hosts
display v0.1.2 and pass readiness. No release activation, registry
reinstallation, new Auth provisioning, or publication was performed.
