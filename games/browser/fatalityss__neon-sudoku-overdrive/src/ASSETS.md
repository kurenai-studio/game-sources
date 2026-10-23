# Assets

The MIT license in [LICENSE](LICENSE) covers the source code only. The audio, image and font files embedded in `index.html` are **not** covered by it. Do not reuse them outside this project without checking the terms below.

| Asset type | Source | Terms |
|---|---|---|
| Announcer voice lines and some sound effects | Generated with [ElevenLabs](https://elevenlabs.io) (free plan) | Non-commercial use only. Attribution required: generated with elevenlabs.io. |
| Three music tracks | Generated with ElevenLabs sound effects (free plan) | Non-commercial use only. Attribution required: generated with elevenlabs.io. |
| Four music tracks (victory, countdown, gameplay 2, boss 2) | Generated locally with [ACE-Step 1.5](https://huggingface.co/ACE-Step) | ACE-Step is MIT-licensed; its model card permits commercial use of generated music. |
| Background, frame, digit and character images | Generated with Google Gemini | Google does not claim ownership of generated content. |
| Fonts: Oxanium, Barlow Condensed | Google Fonts | SIL Open Font License 1.1 |

The source media files are not stored in this repository. `build/build.py` expects them in `media/` and `media-compressed/` when rebuilding.

A per-file source list is planned (see the roadmap in the README).
