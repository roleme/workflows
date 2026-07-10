# Release on dependency updates — design

**Date:** 2026-07-10
**Status:** Approved (pending spec review)

## Problem

`roleme/workflows` publishes shared reusable workflows/actions. Consumers
(`docker_infra`, `asia-trip-bot`, `training_tracker`) pin a SHA with a `# vX.Y.Z`
comment and let Renovate follow new releases. Releases are cut by
release-please, which bumps the version only for release-triggering Conventional
Commit types (`feat:`, `fix:`, breaking).

Renovate authors dependency PRs with the `chore(deps):` prefix (its default
`semanticCommitType`). `chore` is **not** release-triggering, so every Renovate
dependency merge lands on `main` without cutting a release. Result: no releases
since `1.2.0` despite three merged PRs (#26 `chore(deps)`, #30 `chore(deps)`,
#34 `refactor`), and consumers pinning `@v1` never pick up the dependency bumps.

This is not a release-please bug — it is behaving exactly as configured. The gap
is the commit *type* Renovate emits.

## Goal

- A **non-breaking** dependency update cuts a **patch** release of this repo.
- A **breaking** dependency update cuts a **major** release.
- Hand-authored `feat:`/`fix:` work continues to bump minor/patch as before.
- Hand-authored `chore:`/`refactor:`/`docs:` continue to cut **no** release.

Bump mapping chosen (patch-for-deps, major-if-breaking):

| Dependency update | This repo's release |
| --- | --- |
| patch / minor / pin / digest | **patch** |
| major | **major** |

Minor dep updates map to a patch (not a minor) deliberately: for a shared CI
repo, "did our public interface gain functionality?" is what a minor should
mean, and a dependency's own minor rarely does that for our consumers.

## Why auto-major is safe here

A major bump of `roleme/workflows` is **never auto-merged in consumers** — the
shared preset's third `packageRule` sets `automerge: false` for
`roleme/workflows` majors and labels them `breaking-change`, so every consumer's
major PR waits for a human. Patch/minor bumps auto-merge on green CI (rule 2).

Therefore biasing toward "dependency-major ⇒ repo-major" is the safe default:

- Over-declaring a major costs only a **one-click merge** of the already-gated
  PR in each consumer (moving-tag design means no code change).
- Under-declaring (auto-patching something that actually broke consumers) would
  auto-merge silently into every consumer — strictly worse.

The major *release of this repo* is also gated: `release-please.yml` leaves an
`X.0.0` release PR open for manual review (it only auto-merges non-major release
PRs). So a major flows through two human gates: one here, one per consumer.

## Design

All changes are confined to `renovate-presets/default.json`. Nothing in
`release-please.yml`, `release-please-config.json`, or
`.release-please-manifest.json` changes — release-please already does the right
thing given the right commit types.

The change affects **only Renovate-authored commits**. `semanticCommitType`
rewrites Renovate's own commit type; hand-authored commits keep whatever
Conventional Commit type the author writes.

### Edit 1 — retype Renovate dependency commits to `fix`

Add top-level keys to the preset:

```json
"semanticCommits": "enabled",
"semanticCommitType": "fix",
```

`semanticCommits: "enabled"` removes reliance on Renovate's auto-detection,
which sniffs the last ~20 base-branch commits and is brittle right after a
release when several `chore(main): release …` commits dominate.

Effect: `chore(deps): update X` → `fix(deps): update X` → **patch** release.

### Edit 2 — mark major dependency updates as breaking

Add a `packageRule`, placed **first** in the array so it is evaluated for all
managers before the more specific rules:

```json
{
  "description": "Major dependency updates carry a BREAKING CHANGE footer so release-please cuts a MAJOR release of this shared repo. Consumers gate majors manually (see the roleme/workflows major rule below), so a possibly-spurious major is a one-click merge there, never a silent rollout. Non-major updates inherit semanticCommitType=fix -> patch.",
  "matchUpdateTypes": ["major"],
  "commitBody": "BREAKING CHANGE: major version bump of a dependency; review consumer compatibility."
}
```

`commitBody` places the `BREAKING CHANGE:` footer in the commit body.
release-please parses the full commit message (subject + body/footers), so the
footer triggers a major even though the subject is `fix(deps): …`.

### Manual override

For a non-major dependency bump the author knows is behaviorally breaking, retitle
the PR to `fix(deps)!: …`. The `!` lives in the subject, which always survives a
squash, so this path is robust regardless of the squash-body setting.

## Squash-merge dependency (must verify during implementation)

The `BREAKING CHANGE:` footer lives in the commit **body**. Under squash merge,
the final `main` commit body must contain that footer for the major path to
fire. GitHub's squash default composes the body from the PR's commit messages
(preserved), but a repo set to "PR title only" for the squash body would drop
the footer.

**Implementation must verify** the repo's squash body setting:

```
gh api repos/roleme/workflows --jq '.squash_merge_commit_message'
```

- `COMMIT_MESSAGES` or `BLANK`+`PR_BODY` carrying it through → footer path works.
- If it is title-only (`PR_TITLE`), either flip the setting to `COMMIT_MESSAGES`
  or switch the major mechanism to put `!` in the subject instead of a body
  footer (via `semanticCommitType` templating on the major rule).

The manual-override `!`-in-subject path works regardless.

## Edge cases

- **pin / digest / pinDigest updates** — not `patch`/`minor`/`major`, so they
  inherit `semanticCommitType: fix` → `fix(deps): …` → **patch**. A digest
  re-pin becomes a patch release. Intended.
- **`roleme/workflows` self-reference in consumers** — unaffected. Those rules
  govern auto-merge, not commit type. Consumers still gate `roleme/workflows`
  majors.
- **`chore(main): release …` from release-please** — still `chore`, correctly
  ignored; no release-of-a-release loop.
- **Hand-authored `chore:` / `refactor:` / `docs:`** (e.g. #34 `refactor:`) —
  still non-release. Only Renovate's dependency commits are retyped.

## Backlog note

The three commits already on `main` since `1.2.0` (`refactor`, 2× `chore(deps)`)
remain unreleased under this change — it is not retroactive. To release them,
cut a one-off with a `Release-As: 1.2.1` commit on `main` after merging this. Not
baked into the design; flagged for a decision.

## Validation

No unit tests in this repo. Validation is:

1. `renovate-config-validator renovate-presets/default.json` (if available in
   the toolchain) — confirms the preset still parses.
2. Behavioral: the next Renovate dependency PR merges as `fix(deps): …` and
   release-please opens a `chore(main): release 1.2.x` PR.
