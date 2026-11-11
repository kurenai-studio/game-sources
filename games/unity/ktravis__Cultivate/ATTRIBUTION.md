# Attribution — Cultivate

- **Authors / upstream owner:** [Kyle Travis](https://github.com/ktravis) (ktravis)
- **Upstream:** https://github.com/ktravis/Cultivate
- **License:** MIT (see `LICENSE`) — copyright 2015 Kyle Travis (git blob `d4ddf5dd2f29b9fcbc96141e3dfb03c68793d544`)
- **Pinned commit:** `611093831d046104a256598e767aa39964a00079` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference.

**Third-party notes:**
- Engine: Unity 5.3.0f4 (`src/ProjectSettings/ProjectVersion.txt`). This is a pre-package-manager project (no `Packages/` manifest). No TextMesh Pro assets are vendored. No DOTween, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL.
- Playable scenes enabled in the Unity 5.3 binary `EditorBuildSettings`: `Assets/Menu.unity` and `Assets/Main.unity`.
- `src/Assets/runescape_uf.ttf` (md5 `4c8754090a7936fac2f8c5f3043db9ee`) and its `.meta` were omitted. The font name table identifies it as RuneScape UF Regular / FontStruct / nayfan 2010, Version 1.0, licensed as Creative Commons Attribution-No Derivatives (CC BY-ND 3.0, http://creativecommons.org/licenses/by-nd/3.0/). The upstream README incorrectly describes this font as Public Domain. CC BY-ND is not on the redistributable whitelist, and the face is a replica of the RuneScape game font. GUID references may remain in scenes.
- Short UI sound effects under `src/Assets/Resources/Sounds/` are retained under the repository MIT License as original solo Ludum Dare 34 Compo SFX by Kyle Travis (no music was included; the README says the author did not have time to add/create music): `choose.wav` (md5 `44790b5813c6cbbd1efbbc3031ff409d`), `hit.wav` (`16ccf51ce0977bdab6dd59000eb673a3`), `no-choose.wav` (`e726531e69166f6eb0a5801793b3db11`), `stat-down.wav` (`f8fe9dee916b9cee49cb41795e025ce1`), `stat-up.wav` (`61a65f33e9b3605389f08152a8869032`), `static.wav` (`ed8905146cc2876e4ce7f44b0acc6e19`), `step.wav` (`8b20f5dbedda00c31b196a12d819a5f6`).
- Title still `src/Assets/Resources/Images/title.png` (md5 `04124bd51c06f55aad3e7692d85230db`).
- Root `src/index.html` is a leftover Unity WebGL loader that references a `Release/` build directory not present in the repository; it was kept as in upstream.
- Product / jam: Ludum Dare 34 Compo. Preview: http://ludumdare.com/compo/ludum-dare-34/?action=preview&uid=28426
