# Changelog

## [1.4.6](https://github.com/remarkablegames/secret-identity/compare/v1.4.5...v1.4.6) (2026-07-14)


### Bug Fixes

* **api:** improve chat prompt and reduce hallucination ([15ad1d7](https://github.com/remarkablegames/secret-identity/commit/15ad1d7098d1fc745d77a424374db5a6a4ec4e00))

## [1.4.5](https://github.com/remarkablegames/secret-identity/compare/v1.4.4...v1.4.5) (2026-07-14)


### Bug Fixes

* **api:** change the model to `@cf/meta/llama-3.1-8b-instruct-fp8` ([7a233d3](https://github.com/remarkablegames/secret-identity/commit/7a233d3606a7c0b5410b4f4e710591aebbbdbbc5))

## [1.4.4](https://github.com/remarkablegames/secret-identity/compare/v1.4.3...v1.4.4) (2025-09-12)


### Performance Improvements

* **api:** replace model with `llama-3.1-8b-instruct-fast` ([4780e8d](https://github.com/remarkablegames/secret-identity/commit/4780e8d45a8a6fe6072560cedd5afa3e580617c8))

## [1.4.3](https://github.com/remarkablegames/secret-identity/compare/v1.4.2...v1.4.3) (2025-09-10)

### Miscellaneous Chores

- release 1.4.3 ([c60e458](https://github.com/remarkablegames/secret-identity/commit/c60e4580bf3f1e002b9a2b41cc7f0bf3f017182f))

## [1.4.2](https://github.com/remarkablegames/secret-identity/compare/v1.4.1...v1.4.2) (2025-05-03)

### Bug Fixes

- **api:** increase MAX_TOKENS to 150 ([36ca4b0](https://github.com/remarkablegames/secret-identity/commit/36ca4b041de2d08ab135ea3495a17b451c0f179f))

## [1.4.1](https://github.com/remarkablegames/secret-identity/compare/v1.4.0...v1.4.1) (2025-02-11)

### Bug Fixes

- **index:** fix favicon path ([2499c1f](https://github.com/remarkablegames/secret-identity/commit/2499c1fde74ced440ef4169b9d44025585c73508))
- **index:** prepend BASE_URL in favicon path ([457a157](https://github.com/remarkablegames/secret-identity/commit/457a15726daeacc1e4a6e835edb4d5af79016cd4))
- **public:** fix favicon url ([d45d467](https://github.com/remarkablegames/secret-identity/commit/d45d467c6b673bcdc25886f9fa843f02b2361f96))

## [1.4.0](https://github.com/remarkablegames/secret-identity/compare/v1.3.0...v1.4.0) (2024-11-28)

### Features

- **constants:** increase MAX_GUESSES from 6 to 10 ([80ecc0b](https://github.com/remarkablegames/secret-identity/commit/80ecc0b2672945199a3f9f4fc70193776843bc85))

## [1.3.0](https://github.com/remarkablegames/secret-identity/compare/v1.2.3...v1.3.0) (2024-11-22)

### Features

- **constants:** increase MAX_GUESSES from 5 to 6 ([2e901f4](https://github.com/remarkablegames/secret-identity/commit/2e901f4460b0d8356bdd03a6a526ff149e21439f))

## [1.2.3](https://github.com/remarkablegames/secret-identity/compare/v1.2.2...v1.2.3) (2024-11-20)

### Bug Fixes

- **Form:** disable submit button if over max guesses ([f4f9f95](https://github.com/remarkablegames/secret-identity/commit/f4f9f9563ddf359b92bcbf0a00d76f20f58aabc8))
- **helpers:** update localStorage key to use locale date string ([ae3a13a](https://github.com/remarkablegames/secret-identity/commit/ae3a13a85fa7c17d101680fa9e194a074d5683ad))

## [1.2.2](https://github.com/remarkablegames/secret-identity/compare/v1.2.1...v1.2.2) (2024-11-20)

### Bug Fixes

- don't play tick sound on mobile ([343e864](https://github.com/remarkablegames/secret-identity/commit/343e8645f7948dcaf6dfff09b88bda97c55becb1))

## [1.2.1](https://github.com/remarkablegames/secret-identity/compare/v1.2.0...v1.2.1) (2024-11-19)

### Bug Fixes

- **sounds:** decrease volume of sounds ([2e17a80](https://github.com/remarkablegames/secret-identity/commit/2e17a800e368f001e370366a00d9832d479ffd16))

## [1.2.0](https://github.com/remarkablegames/secret-identity/compare/v1.1.0...v1.2.0) (2024-11-16)

### Features

- **sounds:** play Chat interface sounds ([30449a0](https://github.com/remarkablegames/secret-identity/commit/30449a01302fb14009d19e386e54765f8eb0420f))

## [1.1.0](https://github.com/remarkablegames/secret-identity/compare/v1.0.5...v1.1.0) (2024-11-16)

### Features

- allow player maximum 5 guesses per day ([b4d8494](https://github.com/remarkablegames/secret-identity/commit/b4d8494a7f24e64b8a63b7d8e5c12f38098ee3bc))

## [1.0.5](https://github.com/remarkablegames/secret-identity/compare/v1.0.4...v1.0.5) (2024-11-16)

### Bug Fixes

- **api:** decrease max tokens from 100 to 1 ([f07bedf](https://github.com/remarkablegames/secret-identity/commit/f07bedfefe1ee5a0a416ad3755c96814aaf0aac3))

## [1.0.4](https://github.com/remarkablegames/secret-identity/compare/v1.0.3...v1.0.4) (2024-11-15)

### Bug Fixes

- **functions:** catch and show daily quota exceeded error ([bf0d53f](https://github.com/remarkablegames/secret-identity/commit/bf0d53f313005b5637a01b5f5ba66b2dbb0e7f96))

## [1.0.3](https://github.com/remarkablegames/secret-identity/compare/v1.0.2...v1.0.3) (2024-11-15)

### Bug Fixes

- **Form:** change input placeholder to "Type your guess..." ([bbd5691](https://github.com/remarkablegames/secret-identity/commit/bbd569154963aba4eb9fce40762d90fa5b7f36b6))

## [1.0.2](https://github.com/remarkablegames/secret-identity/compare/v1.0.1...v1.0.2) (2024-11-14)

### Bug Fixes

- set body background to gray and chat background to white ([4c827d3](https://github.com/remarkablegames/secret-identity/commit/4c827d38247cbbc72982013fbe1d6a02193fd950))

## [1.0.1](https://github.com/remarkablegames/secret-identity/compare/v1.0.0...v1.0.1) (2024-11-14)

### Continuous Integration

- **github:** fix userversion in release-please.yml ([c875a36](https://github.com/remarkablegames/secret-identity/commit/c875a36253914fefcc2ad133d45de90d40ddb6a2))

## 1.0.0 (2024-11-14)

### Features

- update prompt, assets, and copy ([0229d8e](https://github.com/remarkablegames/secret-identity/commit/0229d8ec6aa23c77b7977b9b0c72f93b809daf0a))
