# Changelog

## [1.3.0](https://github.com/roleme/workflows/compare/v1.2.0...v1.3.0) (2026-07-10)


### Features

* release on Renovate dependency updates ([#35](https://github.com/roleme/workflows/issues/35)) ([15ad824](https://github.com/roleme/workflows/commit/15ad824164c16d0272e2e6e82a1d49379d258849))

## [1.2.0](https://github.com/roleme/workflows/compare/v1.1.1...v1.2.0) (2026-06-29)


### Features

* **renovate:** automerge patch+minor for all managers on green CI ([#27](https://github.com/roleme/workflows/issues/27)) ([6a6dbb4](https://github.com/roleme/workflows/commit/6a6dbb401aeda40646ad84622fba13cf8d24531f))

## [1.1.1](https://github.com/roleme/workflows/compare/v1.1.0...v1.1.1) (2026-06-26)


### Bug Fixes

* retry major-tag move to survive transient 422 after release merge ([#24](https://github.com/roleme/workflows/issues/24)) ([59d6199](https://github.com/roleme/workflows/commit/59d619994fe3e67aa84077849615e282aa0d4065))

## [1.1.0](https://github.com/roleme/workflows/compare/v1.0.0...v1.1.0) (2026-06-26)


### Features

* add composite actions (privacy-scan, komodo-deploy) ([#14](https://github.com/roleme/workflows/issues/14)) ([fe2bcde](https://github.com/roleme/workflows/commit/fe2bcdec9e3cf2494902986076a2044fc892d253))
* add gitleaks + privacy-scan reusables and pre-commit hook ([#13](https://github.com/roleme/workflows/issues/13)) ([2843cba](https://github.com/roleme/workflows/commit/2843cba2ef6fbb4e292e1c808f89dcd23f1ac2d5))
* add pip-audit + trivy reusable workflows ([#18](https://github.com/roleme/workflows/issues/18)) ([a9e3134](https://github.com/roleme/workflows/commit/a9e31348d5d45f6f5bc14e5df51abd815488f533))
* add release-please + zero-cooldown automerge for shared reusables ([#19](https://github.com/roleme/workflows/issues/19)) ([69f6b8b](https://github.com/roleme/workflows/commit/69f6b8b231f3c28f1580a92ecdbc8ef27882e30a))
* add reusable cleanup-ghcr workflow ([#15](https://github.com/roleme/workflows/issues/15)) ([1d7cdf2](https://github.com/roleme/workflows/commit/1d7cdf2cb210754d9b8a74a3a6be58211f0dae86))
* enable transitiveRemediation for Renovate ([fd8b7c7](https://github.com/roleme/workflows/commit/fd8b7c73f3b9b0c05edff7b871307904c1a0626a))
* extract reusable workflows + actions automerge in preset ([#12](https://github.com/roleme/workflows/issues/12)) ([fd888e6](https://github.com/roleme/workflows/commit/fd888e68e33a3cad7759dd96bb1390b0d05c8047))


### Bug Fixes

* add Node.js 24.x setup to Dependabot validate workflow ([#9](https://github.com/roleme/workflows/issues/9)) ([c56440a](https://github.com/roleme/workflows/commit/c56440af5475c5fdfbc3021b6ad9d4cafae29850))
* disable gitleaks PR comments to keep least-privilege ([#16](https://github.com/roleme/workflows/issues/16)) ([fce34f0](https://github.com/roleme/workflows/commit/fce34f0828c8118372f8eee5394c7f9d7f74416e))
* grant gitleaks pull-requests: read for PR commit scan ([#17](https://github.com/roleme/workflows/issues/17)) ([46bccad](https://github.com/roleme/workflows/commit/46bccad718e3f562ede865da866e157df0ea49e8))
* parse release version from PRS json; tag-move via API (no checkout) ([#23](https://github.com/roleme/workflows/issues/23)) ([6bab1e3](https://github.com/roleme/workflows/commit/6bab1e3ce070275bfe660e8cfeee3ab54b810fb7))
* prevent script injection via validate-command input ([#5](https://github.com/roleme/workflows/issues/5)) ([c2f695e](https://github.com/roleme/workflows/commit/c2f695e02a2af12cc5c8b11ba7a279846f6b1b13))
* use PAT for release-please so its PR triggers the required check ([#21](https://github.com/roleme/workflows/issues/21)) ([f7aa8b5](https://github.com/roleme/workflows/commit/f7aa8b52e969a8bf2ca0251b5c56fea1c86b9606))
