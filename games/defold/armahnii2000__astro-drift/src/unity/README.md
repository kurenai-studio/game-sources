# Astro Drift — Unity

The Astro Drift gameplay (same Asteroids game as the Godot version) translated into Unity C# `MonoBehaviour` scripts, targeting **Unity 2022.3 LTS**.

## Engine twist — Unity-flavored juice

The same game with Unity-signature additions:

- **`ThrustTrail.cs`** — drives a `ParticleSystem` emission rate from the input axis. When you thrust, a particle trail streams behind the ship; when you stop, it fades. This is the canonical Unity "feel" feature that distinguishes a real Unity game from a code-only port.
- **`CameraShake.cs`** — trauma-based screen shake on the main camera. Other systems call `AddTrauma(amount)`; trauma decays each frame and shake intensity is `trauma²` so small hits barely register, big hits (asteroid split, player death) really rattle.
- **`ExplosionEffect.cs`** — a `ParticleSystem` burst spawned at asteroid destruction with size-scaled emission. Triggers a `CameraShake.AddTrauma(...)` proportional to asteroid size and plays a `PlayClipAtPoint(impactClip, ...)` for audio.
- **`SfxManager.cs`** — singleton audio service with a `SoundId` enum (`Shoot`, `AsteroidHit`, `PlayerDeath`, `WaveStart`). Scripts call `SfxManager.Instance.Play(SoundId.Shoot)` from gameplay events.

These together make the Unity version feel polished in a way the others can't easily match — particles, trauma-based shake, and event-driven audio are all *signature Unity affordances*.

## Open & build

1. Install [Unity Hub](https://unity.com/download) and **Unity 2022.3 LTS** with the WebGL Build Support module.
2. **Open → Add project from disk**, select this `unity/` directory.
3. On first open Unity will generate the `Library/`, `Temp/`, and per-asset `.meta` files (gitignored).
4. Create the scene: an empty `Player` GameObject with `PlayerController` + `ThrustTrail` components (assign a ParticleSystem child); an `Asteroid` prefab with `AsteroidController` + `CircleCollider2D`; a `Bullet` prefab with `BulletController` + `CircleCollider2D`. Attach `CameraShake` to the main camera, `SfxManager` to a persistent root GO, drop an `ExplosionEffect` prefab.
5. **File → Build Settings → WebGL → Build**. Output goes to `Build/`.

## Files

```
Assets/Scripts/
  PlayerController.cs    — input, inertial physics, screen wrap, bullet spawning
  BulletController.cs    — lifetime, screen wrap, OnTriggerEnter2D against asteroids
  AsteroidController.cs  — drift, spin, size-tier splitting
  GameManager.cs         — wave/score/lives loop
  ThrustTrail.cs         — engine particle emission driver  (twist)
  CameraShake.cs         — trauma-based screen shake        (twist)
  ExplosionEffect.cs     — burst particles + shake + audio  (twist)
  SfxManager.cs          — singleton audio service          (twist)
Packages/manifest.json   — UPM dependencies
ProjectSettings/ProjectVersion.txt — editor version pin
```
