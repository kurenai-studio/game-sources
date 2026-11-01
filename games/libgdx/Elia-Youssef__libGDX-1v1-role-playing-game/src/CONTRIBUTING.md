# Contributing

Thanks for helping improve Immortal Combat.

## Local workflow

1. Create a focused branch from the latest default branch.
2. Keep gameplay rules in `PlayerController` when they do not require libGDX APIs.
3. Add or update tests for every behavior change.
4. Run `./gradlew clean build` before opening a pull request.
5. Launch `./gradlew lwjgl3:run` when a change affects rendering, input, audio, or assets.

On Windows, use `gradlew.bat` in place of `./gradlew`.

## Code style

- Use clear domain names and small methods with one responsibility.
- Prefer tests over comments that repeat the implementation.
- Explain constraints or non-obvious decisions in comments.
- Keep the controller independent from rendering and platform APIs.
- Preserve Java 8 source compatibility and the pinned libGDX version unless a version change is the
  explicit purpose of the pull request.

## Assets

Every action must keep three distinct 256x256 PNG frames. Run the full test suite after changing an
image or `woosh.wav`; asset integrity is checked as part of the build.

Only contribute assets that you have permission to distribute. Include attribution or license
details when an asset's terms require them.

## Pull requests

Please keep pull requests small enough to review comfortably and include:

- A short explanation of the player-facing change
- The verification commands you ran
- Screenshots or a short recording for visual changes
- Any compatibility or asset-licensing considerations
