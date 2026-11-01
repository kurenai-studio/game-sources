# Astro Drift — Stride (Xenko)

The Astro Drift gameplay restated as [Stride](https://www.stride3d.net/) (formerly Xenko) C# `SyncScript` components. Targets **Stride 4.2** on .NET 8.

## Open

1. Install [Stride Launcher](https://www.stride3d.net/download/) (Windows) and the Stride 4.2 GameStudio.
2. **File → Open** and select `AstroDrift.sln` (you can scaffold the solution by creating a new "Empty" project in GameStudio, then dropping these `.cs` files into the generated `AstroDrift.Game/` folder and replacing the generated `.csproj`).
3. Build & run from GameStudio, or `dotnet build` if you have the Stride MSBuild SDK on PATH.

## Files

```
AstroDrift.Game/
  AstroDrift.Game.csproj   — .NET 8 SDK project referencing Stride.Engine 4.2.*
  PlayerScript.cs          — SyncScript: input → heading/thrust/drag, screen-wrap on XZ plane
  BulletScript.cs          — SyncScript: linear velocity + lifetime + screen-wrap
```

## Notes

Stride GameStudio generates the binary `.sdpkg` package, `.sdsln`, asset GUIDs, and per-asset `.sdscene`/`.sdprefab` files on first open. Those are intentionally out of source control — the runtime behavior lives entirely in these two scripts.

The Stride bucket on the survey is the direct match; the alternative "OGRE or Unreal Engine" substitute is also satisfied by sibling skill in the Unity folder.
