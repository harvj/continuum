# Continuum release versions

`VERSION` is the application version for each Git revision. It contains
`MAJOR.MINOR.PATCH` without the `v` prefix. The first release bootstraps the
file to `0.1.0` before any tags or releases exist. Rails reads it once at boot
from its release directory. All three landing pages render the same version.
An archive contains everything required for version resolution.

Deployment archives an exact reviewed commit, including `VERSION`. Check
the commit and version before switching `current`, then restart Continuum and
check the footer on Network, Library, and Intelligence. Rolling back switches
`current` to the previous release and restarts Continuum. That release's
`VERSION` is read at boot.

## Preparing and publishing a release

1. Set `VERSION` to the next stable version in the release candidate. Run CI,
   including the version consistency, footer, and symlink rollback tests.
2. Deploy the reviewed commit using the [deployment plan](CONTINUUM_DEPLOYMENT.md).
   Verify its revision, readiness, neighbor baselines, and public footers.
3. After production verification, create the matching `vMAJOR.MINOR.PATCH`
   tag at the exact approved commit. Run
   `bin/verify-release vMAJOR.MINOR.PATCH DEPLOYED_SHA` and push the tag.
   Publish the GitHub release from that existing tag using the release notes.

The [release-sync workflow](../.github/workflows/release-sync.yml) verifies tag
pushes, published release events, and manual checks. It resolves lightweight
and annotated tags to their commit and compares the tag with the `VERSION`
blob at that revision. Event-triggered runs also check the event SHA.
The workflow has read-only permissions and no production credentials. It
cannot create tags, publish a release, or change the running version.

## SH-07 exact-artifact release identity

The existing packaged version remains the default for legacy releases.
Enable SH-07 for a reviewed release only with the trusted launch and receipt
store below. This is separate from acceptance of the signed Shell v2
production policy.

### Package and bind

The release operator provisions a persistent store outside the application
release pointer. The Rails account needs read-only access to the unpacked
release, launch binding, and the published receipt directory. Keep the
store and its numbering ledger writable only by the authorized release
workflow. Keep private keys outside the store and off the Rails host.
The runtime trust key is the pinned public Ed25519 key for the release
workflow.

Run from the reviewed Git checkout with an exact commit and the authorized
release signer. The store must already exist.

```sh
bin/release-identity prepare "$release_store" "$candidate_sha" development
bin/release-identity prepare "$release_store" "$candidate_sha" candidate
```

`CONTINUUM_RELEASE_SIGNING_KEY` names the release workflow's private key.
The command archives the Git object, hashes the exact retained archive,
allocates a durable RC number per target version under a local lock, and
prints the identity, archive path and unpacked release path. Repeating the
same archive reuses the issued number. Changed archive bytes receive a new
number. Keep the store intact across rollback and workflow retries. Seal
on the approved packaging runner using the same canonical path that the
service will see, then transfer the tree and signed records through the
reviewed deployment workflow. The signed
launch record binds the canonical unpacked path and a source-tree digest
to the archive and source commit. Generated bundle and operational
directories are outside the Git archive digest. Provision them through
the existing reviewed deployment process.

Point the application to that unpacked release only after the release gate.
Set `CONTINUUM_RELEASE_STORE` and `CONTINUUM_RELEASE_TRUST_KEY` on the
running service. Rails verifies the signed launch record and tree once at
boot. Development shows `vX.Y.Z-dev` and numbered candidates show
`vX.Y.Z-rc.N`. Moving the activation symlink leaves the running process's
identity bound to the original release. A configured release with an
invalid launch record fails at boot.

### Record verified acceptance and publication

The authorized acceptance workflow verifies the running exact artifact and
required checks before attesting. The publication workflow verifies the final
tag resolves to the full candidate source SHA and the published asset or
authenticated publication receipt identifies the same archive digest. Use
their protected evidence signers. The packaging command cannot generate
either attestation by itself.

The external signers create records with these fields:

| Record | Exact schema-1 fields |
| --- | --- |
| Acceptance | `schema_version`, `kind: acceptance`, full `candidate`, immutable `reference`, UTC `accepted_at` |
| Published artifact | `schema_version`, `kind: published-artifact`, full `candidate`, immutable `reference`, final `tag`, exact `tag_source_sha`, exact `artifact_sha256`, UTC `published_at` |

Each signed envelope contains the JSON record as a `payload` string and
the Base64 Ed25519 `signature` of those exact UTF-8 bytes. The Ruby
`ContinuumReleaseIdentity.seal` helper produces the envelope. Dates use UTC
with whole seconds. Keep the cited acceptance and publication evidence
independently reviewable. A tag or a source SHA alone provides no evidence
of the published archive.

After both attestations are verified, run the offline importer as the
authorized release workflow. Pin the two trusted evidence public keys
through `CONTINUUM_ACCEPTANCE_TRUST_KEY` and
`CONTINUUM_PUBLICATION_TRUST_KEY`.

```sh
bin/release-identity publish "$release_store" "$signed_acceptance" "$signed_publication"
```

The importer verifies both signatures, the issued candidate record, retained
archive digest, exact tag and target version, and chronology. It installs
one atomic, non-replaceable signed final receipt per version. Retrying the
same evidence is safe. Missing, invalid or contradictory evidence leaves
the prior receipt intact. The running footer checks only this local
receipt on render, picks up promotion on the next render without a
restart, and keeps its accepted label during upstream failure. A restarted
process sees the durable receipt for its own artifact. Application rollback
reselects the old launch record and its own receipt while keeping all
issued candidate numbers and receipts in the persistent store. For rollback
to a legacy release, restore its legacy environment along with the
artifact. Treat recovery from local store loss or signing-key rotation as
an explicit operator recovery with backups and review.

Production use requires approved signer/key custody, read-only runtime
access and the current signed production gate. Disposable fixture signatures
serve local verification only.
