# Versioning

`roleme/workflows` is a shared CI repo. Consumers SHA-pin a release and let
Renovate follow new versions, so this repo's version number is a promise about
**our** interface, not about our dependencies.

## Bump mapping

| Change | Release |
| --- | --- |
| Dependency patch / minor / pin / digest | **patch** |
| Dependency **major** | **minor** |
| Breaking change to **our own** interface | **major** |

A dependency's major is a fact about *that dependency's* interface. Consumers
call our reusable workflows, whose inputs and outputs are unchanged by it — so
it does not warrant a major here. It becomes a minor, which keeps the signal
that something notable moved without inflating our major version.

Mechanism: Renovate commits non-major updates as `fix(deps):` (patch) and major
updates as `feat(deps):` (minor), both set in `renovate-presets/default.json`.
Dependency majors therefore appear under "Features" in `CHANGELOG.md` — a
cosmetic cost accepted in preference to maintaining custom changelog sections.

## What our public interface is

Consumers touch exactly three things:

1. The `workflow_call` **inputs, outputs and secrets** of each `*-reusable.yml`
2. The **inputs and outputs** of each composite action (`komodo-deploy`,
   `privacy-scan`)
3. **`renovate-presets/default.json`** — anything extending it inherits
   behaviour changes

## When to bump MAJOR

Bump major when a change to any of the above **breaks a consumer that did
nothing**:

- Remove or rename an input, output or secret
- Make an optional input required, or remove its default
- Add a new **required** input
- Change an input's type, or narrow its accepted values
- Change the default behaviour of an existing input (e.g. a scan that warned
  now fails the build)
- Delete a reusable workflow or action, or rename its file or path
- In the preset: enable something that fails builds, or change an `automerge`
  or gate so consumers merge something they previously reviewed by hand

The preset is the easiest of the three to break silently — a preset change can
alter behaviour in every consumer without touching a single input. Treat a
gate-loosening preset change as major even though no interface moved.

## When NOT to bump major

- Adding an **optional** input with a default that preserves current behaviour
- Adding an output
- Any dependency bump, including a major (→ minor)
- Internal refactors, SHA pinning, docs
- Adding a new reusable workflow or action

## Authoring a major

Put `!` in the commit subject: `feat!: …` or `fix(deps)!: …`. The subject always
survives a squash merge, so this works regardless of the repo's
`squash_merge_commit_message` setting. A `BREAKING CHANGE:` footer in the body
also works (this repo is set to `COMMIT_MESSAGES`, so bodies are preserved), but
the subject form is more robust.

This is a convention, not an enforced rule: `main` requires the `zizmor` status
check but has no required reviews and no push restrictions, so a `!` commit can
reach `main` without review. Enforcing it would need a branch-protection change.
