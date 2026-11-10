# Attribution — LD39

- **Authors / upstream owner:** Mergers and Acupuncture ([MergersandAcupuncture](https://github.com/MergersandAcupuncture)); git author David Jerome
- **Upstream:** https://github.com/MergersandAcupuncture/LD39
- **License:** Apache-2.0 (see `LICENSE`; appendix copyright 2017 Mergers and Acupuncture)
- **Pinned commit:** `bd6f04c347b3cbf50e4ec8da1c24eff9e5413d6c` (default branch `develop`)
- **Collected by:** bot e
- **Collected at:** 2026-11-10 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The authors licensed the work under the Apache License 2.0.

**Third-party notes:**
- Upstream bundled a copy of [prime31/CharacterController2D](https://github.com/prime31/CharacterController2D) at `src/Assets/Scripts/Motor/CharacterController2D.cs`. That library is licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/) and cannot be redistributed here (non-commercial clause). It was omitted and replaced with an original kinematic 2D mover written for this snapshot, kept under the same file name and the small API used by `PlayerMotor` (`isGrounded`, `velocity`, `move`). The replacement is Apache-2.0. `PlayerMotor.cs` no longer imports the `Prime31` namespace.
- Artwork (sprites and FBX models) and two WAV clips (`casulScrubMusic01.wav`, `Audio_Hit.wav`) are included in the upstream tree under the same Apache-2.0 license.
- No bundled fonts, no DOTween, no EmojiOne, no FXAA, no Unity Standard Assets, no Asset Store packages, no LFS, no DLL/EXE.
- Unity 2017.1.0f3. Product name: LD39 (Ludum Dare 39, "Running out of Power"). Playable `Assets/Scenes/LevelGeneratorTest.unity` with player, pickups, and obstacles.
