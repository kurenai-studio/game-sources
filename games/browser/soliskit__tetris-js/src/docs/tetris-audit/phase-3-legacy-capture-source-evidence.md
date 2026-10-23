# Released Save Capture Records

Compare the capture account with the released serializers without regenerating fixtures.

This record compares the written account of fixture capture with the historical serializers. It is documentary capture attestation and historical writer consistency, not independently replayed original capture, regenerated fixtures or phase closure.

## Recorded source and expected relation

STA-6 concerns fixture contents actually written by released versions. The fixture-introduction README at commit states that fixtures were made by playing a seeded game with each release's own code until a line cleared, then holding, turning/moving and pausing. It distinguishes the older with-level format window from the later no-level format. Those "release" windows are repository states/merges here, not independently bound deployed releases. The fixtures were introduced later than the represented formats. Introduction commit prose repeats that capture method.

The introduction author is identified in public commit metadata as an AI coding assistant. These are repository-authored provenance statements, not authenticated owner claims or independent execution receipts. They establish that an account of capture exists. Fetching them does not establish that every detail is true.

## Mapped documentary method

The method identifies the first fixture bytes and preserves them, binds the stated release window, compares the corresponding historical serializer key sets with fixture fields, and separately compares independent semantic decode with current Continue behavior. The serializer key sets match their corresponding fixture fields. This does not reproduce stored values or prove runtime capture. The latter comparisons test writer consistency and interpretation, not a recreation of the original seeded action history.

Exact seed, complete inputs, raw storage-capture log, original execution environment and independently verified release-deployment binding were not recovered in the held inspection. Bounded archive absence is not proof that capture did not occur. STA-6 does not itself require a seed/log to be preserved. Missing independent execution attestation remains an evidence limit, not an invented requirement.

Recorded capture attestation plus historical writer consistency is a bounded provenance relation, with dependence on the repository author's account explicit. It is not universal fixture authenticity proof. Modern regeneration or a new Continue run cannot repair a fixture's historical origin. The original fixtures remain untouched. No owner authority or identity follows from commit-author prose.

## Exact historical bindings

At introduction:

| File | Git blob | SHA-256 |
| --- | --- | --- |
| `test/fixtures/README.md` | `4ff5cd49adc329b0caa32612959a4ee4feb39874` | `a073f21ee6855acef2df84bef471c24da4c4b29f90aacca0fc72733a9955d8df` |
| `test/fixtures/saved-game-current.json` | `9c49d9f7e77de4a48a4bd3594c96eaea8d1da300` | `5db92314408a59661f17e47887778df96de91e19ae433827b1f74a42227e126e` |
| `test/fixtures/saved-game-with-level.json` | `2e1326b248b71c17038dd672e6173be31f74fe0d` | `c628f4442aab487f185b2ba88c58adce6fbf6c55310c3f0314e1dc1e7abc1ebb` |

All three blobs are unchanged at documentation merge. The `public/game/session.js` with-level serializer at PR26 merge `d0b53e8` has SHA-256 `4670e8b9348c747cdc2f5ed27b447f435a4587606512264dec622fbc269545c1`; the no-level serializer at `402a4b7` has SHA-256 `632f3b417ec9bcd837203b07054c45bda3a4289264620a6a38da61ccc69e6171`. serializeSession supplies the named field-set comparison, not an original capture replay.

## Status-label publication migration

The fixture README hash above identifies the documentation inspected for the original capture analysis. Its later title-case change-class reference has a new publication identity in the migration receipt. Both JSON fixture files and all original capture/serializer identities remain unchanged.
