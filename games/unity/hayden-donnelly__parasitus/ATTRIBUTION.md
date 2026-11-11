# Attribution — parasitus

- **Authors / upstream owner:** [hayden-donnelly](https://github.com/hayden-donnelly) (Hayden Donnelly)
- **Upstream:** https://github.com/hayden-donnelly/parasitus
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `b9e6930330248fa3dbbdbd7b7be82be03a9cb87c` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License (Copyright 2023 Hayden Donnelly).

**Third-party notes:**
- Official Unity packages (Unity 2021.3.4f1) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: Universal Render Pipeline 12.1.7; TextMesh Pro 3.0.6; ProBuilder 5.0.7; Timeline 1.6.4; uGUI 1.0.0; Visual Scripting 1.7.8; Collab Proxy; Rider / Visual Studio / VS Code IDE packages; test framework; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scenes do not require it.
- Upstream tracks images, audio, models, and fonts with Git LFS. The LFS objects were pulled at the pinned commit and stored here as regular git blobs; `filter=lfs` rules were removed from `src/.gitattributes` so this snapshot has no LFS dependency.
- TMP Documentation (User Guide PDF) was omitted. No TMP Examples & Extras were included.
- Sound effects under `src/Assets/Sounds/` and original Blender/XCF character sources under `src/NonUnityFiles/` are included under the repository MIT License. The upstream README does not list separate third-party audio credits.
- `src/Assets/Textures/placeholder_zombie_face.png` (md5 `476e83325d9d992034a4748e7a2bd074`, 1024×1024) is a third-party AI-generated image. It has a visible DALL-E watermark in the bottom-right corner. Embedded EXIF MakerNote is `OpenAI` and UserComment is `Made with OpenAI Labs`. Credited to DALL-E / OpenAI. Retained (the review asked to credit this image, not omit it); it is not under a separately documented whitelist OSS license besides the repository MIT claim.
- `src/Assets/Textures/creepy_woman_painting.png` (md5 `db098d1a723e1c443b9342e7f82fe79c`, 1024×1024) has no visible DALL-E watermark in the pixels, but its EXIF contains `OpenAI` and `Made with OpenAI Labs`. XMP/EXIF also record an edit in GIMP 2.10.32 on 2023-05-01 20:25:01-04:00 (Windows). Credited to DALL-E / OpenAI on that metadata evidence; the file appears to have been re-exported from GIMP (possibly after cropping). Retained and credited rather than omitted.
- `src/Assets/Textures/drywall_tileable.png` (md5 `4af95c386bd4e8056a41b7f218b86454`) and `src/Assets/Textures/plywood_tileable.png` (md5 `4eb6d6151a08c05911cf56e705ffed36`) were omitted together with their `.meta` files. They have no pack credit in this snapshot, the upstream README, the itch.io page, or the Ludum Dare 53 entry; both were last saved from GIMP 2.10.32 on 2023-05-01, and could not be matched to a specific ambientCG / Poly Haven / FreePBR / 3dtextures.me entry. They still look like typical photogrammetry / PBR seamless materials and cannot be treated as confirmed-original, so they are omitted under the verified_only rule. Scene GUID references may remain, consistent with other omitted assets.
- `src/Assets/Textures/door.jpg` (md5 `8c635b5da1d2575844fb220096ab114f`, 243×616 JPEG) is a casual photograph of a real six-panel pine interior door with a round silver knob. It has only a JFIF header (no EXIF camera or stock metadata) and no pack or stock credit in upstream materials. Upstream has no contrary credit; it is noted here as apparently the author’s own photograph.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL, no `.DS_Store`. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: Ludum Dare 53 — Delivery (itch.io: Parasitus). Playable scenes in EditorBuildSettings: `Assets/Scenes/MainMenu.unity`, `Assets/Scenes/Main.unity`, `Assets/Scenes/GameOver.unity`, `Assets/Scenes/GameComplete.unity`.
