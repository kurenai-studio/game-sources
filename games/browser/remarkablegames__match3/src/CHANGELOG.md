# Changelog

## [1.0.1](https://github.com/remarkablegames/match3/compare/v1.0.0...v1.0.1) (2026-08-26)


### Bug Fixes

* **vite:** set base to relative path ([2a3a97e](https://github.com/remarkablegames/match3/commit/2a3a97e644c0a14afc49f8b38207a595f44d176e))

## 1.0.0 (2026-08-26)


### Features

* add combo multiplier scoring and tile fall/gravity animations ([e8e267c](https://github.com/remarkablegames/match3/commit/e8e267ceaf8c37a40e7984274b8244c49bdc9bc7))
* add level-based scaling ([55d5400](https://github.com/remarkablegames/match3/commit/55d5400cc26a28438fdd1faad60e887f47c1c48f))
* add Match3 game with canvas renderer, audio, and input handling ([d52e52a](https://github.com/remarkablegames/match3/commit/d52e52a853a5f0f4758fe58a452747c58228a1e8))
* improve HUD layout with single-line stats and colored separators ([32dc3f1](https://github.com/remarkablegames/match3/commit/32dc3f184cadfd84f582edf84771a941f8743142))
* **renderer:** show mode-specific game over titles and final score ([2f9bab6](https://github.com/remarkablegames/match3/commit/2f9bab624d0620dfeca421f9bee2458ab3b77f0f))


### Bug Fixes

* animate swapped emojis into their new positions ([5c7c962](https://github.com/remarkablegames/match3/commit/5c7c9628f2dc11d413292c0851f7b9c0f53f00f8))
* **audio:** increase volume ([bd1432e](https://github.com/remarkablegames/match3/commit/bd1432e10f9ba8bfa88d7dbe0b740668348f0e1f))
* fix header overlap ([0ff3331](https://github.com/remarkablegames/match3/commit/0ff33315f410fbd3c56a48c9b9573919c356c6c3))
* **input:** allow taps on bottom buttons on mobile ([d819538](https://github.com/remarkablegames/match3/commit/d819538d9611aff951fafbe45dff03e798129fc9))
* **input:** hide keyboard cursor when using pointer input ([fb99d48](https://github.com/remarkablegames/match3/commit/fb99d48b8330ddf0a35bb11c6cdda39bbaddc088))
* **input:** read current state in handlers to avoid stale game-over check ([beeeb69](https://github.com/remarkablegames/match3/commit/beeeb69e79e83c740415ffc7700b9c76b5fb999f))
* lower game over lose volume ([8d6c5dc](https://github.com/remarkablegames/match3/commit/8d6c5dca4545e47a9dc987f0b76c5be3f4c80f7e))
* **renderer:** center game over text ([d7e30e2](https://github.com/remarkablegames/match3/commit/d7e30e2028bb4ed4c32f9412a840bb90bbc87219))
* **renderer:** split header into two lines on mobile ([3a49194](https://github.com/remarkablegames/match3/commit/3a4919475ba857f49706478365c25f76c6f7bde6))


### Performance Improvements

* cap DPR and render only when dirty to reduce CPU/memory usage ([f15d201](https://github.com/remarkablegames/match3/commit/f15d2016eeb14dc5dabf8a8f99fecfb89b40ab8d))
