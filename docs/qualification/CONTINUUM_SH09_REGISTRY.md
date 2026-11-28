# Continuum v0.2.0 production gate follow-up

**Disposition (2026-11-23) — local SH-09 lifecycle passed. Production remains
blocked.** The tested candidate is
`57b286551b14bbb6a746a6d842d563e72421ab2a`. The SHA-256 of the tested Git
archive is
`4f1cb0290291193e6b87f0eeba470b46b1ab531cfb889a7a2cb7e4dafb17284d`.

The candidate adds only a registry withdrawal fix and its regression test
to the previous [Auth candidate and qualification](CONTINUUM_AUTH_PRODUCTION_GATES.md).
Its anonymous layout, footer presentation, Site Art records, and Auth
implementation carry forward. Optional [Shell v2 evidence](APPLICATION_SHELL_V2.md)
and v2 SH-07 release identity stay separate.

## SH-09 lifecycle evidence

The test uses the existing publisher fixture and registry writer from
reviewed Infrastructure revision
`84b631269fea351e146fc01babe9bcbb12edb283`, with disposable Ed25519 keys and
a persistent local cache. It drives the actual Continuum reader in separate
Rails processes against the same cache. It does not create a separate
registry or write substitute cache bytes.

| Case | Observed behavior |
| --- | --- |
| Cold start and refresh | No file yields no destinations. The running process consumes the verifier's first signed snapshot, preserves registry order and excludes Continuum itself. |
| Publisher expiry | The verifier rejects an expired signed pointer. The last verified cache stays byte-identical. |
| Unavailable publisher | A failed fetch cannot replace the cache. A fresh Continuum process still reads the verified snapshot. Empty Auth eligibility yields no links even when the cache is usable. |
| Recovery and withdrawal | A newer verified publication withdrawing Continuum Engine is adopted by both running processes. Other verified destinations remain available. |
| Replay, rollback and restart | The verifier rejects both a replay of the earlier pointer and a lower specification version at a higher sequence. Cache bytes and destination order remain stable across restart. |

The previous reader rejected complete snapshots containing a valid
`withdrawn` entry. That kept the old destination available. The candidate
accepts both signed availability values and filters withdrawals out of
the rendered list.

Separately, `bin/application-shell-registry` verified the actual signed
current **v1.3.0** bundle at sequence 41 and emitted a local cache. Continuum
read that cache and returned Muzeum, Remote-Gaming, and Continuum Engine in
registry order for fixture grants. Signed preflight discovery confirmed
v1.3.0 for the exact candidate and listed no Continuum exceptions.
All 23 Rails tests passed with PostgreSQL and both signed fixture sets
(506 assertions). The signed lifecycle regression passed from the exact
candidate archive.

To repeat the local lifecycle test, export a reviewed Infrastructure
archive using the revision above, then run:

```sh
CONTINUUM_INFRA_QUALIFICATION_ROOT=/path/to/reviewed/archive \
  python3 -m unittest discover -s tests -p test_shell_registry_lifecycle.py
```

## Production blockers and owners

| Owner | Outstanding evidence or disposition |
| --- | --- |
| Infrastructure, SH-02 | The review owner confirmed that signed v1.3.0 requires visible local Log In. White Sands-owned entry without that link needs a forward signed applicability decision covering all three anonymous roots. The exact-candidate evidence was sent for review. No signed decision was issued. |
| Infrastructure, SH-06 | The review owner confirmed that the below-target Library and Intelligence sampled footer/credit text needs a separate signed production disposition. The [prior measurements and focus evidence](CONTINUUM_V0.2.0_PREFLIGHT.md) were sent for review. The 17.7563:1 Intelligence inter-band reading is focus evidence only. The v2-only [PR #20](https://github.com/harvj/infrastructure/pull/20) cannot supply a v1.3.0 waiver. |
| Auth / White Sands, SH-03/04/05 | Auth's read-only handoff confirmed that production Auth v0.5.0 has no Network, Library or Intelligence callback registrations. The separate Continuum Engine registration does not cover these hosts. The v1 evidence contract maps one exact requester ID per canonical application ID. The three-to-one requester mapping, host-local registrations, callback and entry approval, and real White Sands sessions, claims, grants and invalidation evidence are outstanding. |
| Continuum operator and Infrastructure, SH-09 | The disposable verifier/cache lifecycle passed. Read-only inspection found no Continuum cache or refresh unit on the production host. The stock verifier writes its private cache with mode 0600. The existing Remote Gaming integration uses a separate root-owned scheduled verifier and a root-owned 0644 registry for the application to read. Before activation, qualify an approved Continuum-owned installation of the established verifier with a persistent cache outside release directories, an application-readable and application-nonwritable handoff, and refresh and rollback on the intended service identities. |

The final signed production review and full release rehearsal are gated on
the missing decisions and owner evidence. Production still runs v0.1.2 at
`7c2d9cb797d0340b590ffa8439df607126bd18df`. No release preparation step
changed production, its neighboring processes, or the signed current
pointer.
