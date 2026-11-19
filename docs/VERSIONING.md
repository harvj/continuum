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
