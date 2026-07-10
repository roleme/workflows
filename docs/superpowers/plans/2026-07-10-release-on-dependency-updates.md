# Release on Dependency Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every non-breaking Renovate dependency update cut a patch release of `roleme/workflows`, and every breaking one cut a major, by retyping Renovate's commits in the shared preset.

**Architecture:** Change is confined to `renovate-presets/default.json`. Set `semanticCommitType: "fix"` so Renovate dependency PRs commit as `fix(deps):` (patch); add a `matchUpdateTypes: ["major"]` packageRule with a `BREAKING CHANGE:` `commitBody` so major dep updates cut a major. release-please and the release workflow are unchanged. Includes a repo-setting verification because the breaking footer travels in the squash commit body.

**Tech Stack:** Renovate config (JSON preset), release-please, GitHub Actions, `gh` CLI.

## Global Constraints

- Only `renovate-presets/default.json` changes; do not touch `release-please.yml`, `release-please-config.json`, or `.release-please-manifest.json`.
- `semanticCommitType` affects only Renovate-authored commits; hand-authored commit types are untouched.
- Bump mapping: dep patch/minor/pin/digest → repo **patch**; dep major → repo **major**.
- Preserve the existing three `packageRules` and all top-level keys; additive edits only.
- Branch already exists: `docs/release-on-dep-updates`. Commit here; do not push or open a PR until asked.

---

### Task 1: Verify squash-merge body preserves the BREAKING CHANGE footer

The major path relies on the `BREAKING CHANGE:` footer surviving into the squashed `main` commit body. Confirm the repo's squash setting before depending on it.

**Files:**
- None (investigation + decision record).

**Interfaces:**
- Produces: a decision — either "footer path works as-is" or "use `!`-in-subject for majors" — consumed by Task 3's mechanism choice.

- [ ] **Step 1: Read the repo's squash-merge body setting**

Run:
```bash
gh api repos/roleme/workflows --jq '{squash_body: .squash_merge_commit_message, squash_title: .squash_merge_commit_title, allow_squash: .allow_squash_merge}'
```
Expected: a JSON object, e.g. `{"squash_body":"COMMIT_MESSAGES","squash_title":"PR_TITLE","allow_squash":true}`.

- [ ] **Step 2: Decide the major mechanism**

- If `squash_body` is `COMMIT_MESSAGES` → the `BREAKING CHANGE:` footer is preserved. Proceed with the `commitBody` approach in Task 3 (Option A). No change needed.
- If `squash_body` is `PR_BODY` → the footer survives only if Renovate writes it into the PR body; it does with `commitBody`. Proceed with Option A.
- If `squash_body` is `BLANK` (title-only body) → footer is dropped. Choose ONE:
  - **A′ (preferred, no repo change):** in Task 3, replace the `commitBody` rule with a subject-marker rule so the `!` lands in the always-preserved subject:
    ```json
    {
      "description": "Major dependency updates use fix(deps)! so release-please cuts a MAJOR release; the ! lives in the subject, which survives a title-only squash body. Consumers gate roleme/workflows majors manually.",
      "matchUpdateTypes": ["major"],
      "semanticCommitType": "fix",
      "commitMessageExtra": ""
    }
    ```
    and additionally set the subject `!` — Renovate has no direct `!` toggle, so instead flip the repo setting (next option).
  - **B (repo change):** set the squash body to preserve commit messages:
    ```bash
    gh api -X PATCH repos/roleme/workflows -F squash_merge_commit_message=COMMIT_MESSAGES -F squash_merge_commit_title=PR_TITLE
    ```
    then proceed with Option A in Task 3.

  Record which option you took in the commit message of Task 3.

- [ ] **Step 3: No commit**

This task produces a decision only; nothing to commit.

---

### Task 2: Retype Renovate dependency commits to `fix` (patch releases)

**Files:**
- Modify: `renovate-presets/default.json` (top-level keys, after line 10 `"platformAutomerge": false,`)

**Interfaces:**
- Consumes: nothing.
- Produces: Renovate dependency PRs now commit as `fix(deps): …`, which release-please maps to a patch.

- [ ] **Step 1: Add the semantic-commit keys**

In `renovate-presets/default.json`, immediately after the line `"platformAutomerge": false,` (line 10) and before `"ignoreTests": false,`, insert:

```json
  "semanticCommits": "enabled",
  "semanticCommitType": "fix",
```

Rationale to keep as inline context (no code comment needed — JSON has none): explicit `semanticCommits: "enabled"` avoids Renovate's brittle auto-detection, which sniffs the last ~20 commits and is skewed by `chore(main): release …` commits right after a release.

- [ ] **Step 2: Validate the preset still parses**

Run (validator is fetched on demand; falls back to a JSON syntax check if offline):
```bash
npx --yes --package renovate -- renovate-config-validator renovate-presets/default.json \
  || python3 -c "import json,sys; json.load(open('renovate-presets/default.json')); print('JSON OK')"
```
Expected: `INFO: Config validated successfully` (or `JSON OK` on the fallback). No `ERROR` lines.

- [ ] **Step 3: Commit**

```bash
git add renovate-presets/default.json
git commit -m "feat: emit fix(deps) so dependency updates cut a patch release

Renovate defaulted to chore(deps): which release-please ignores, so no
release was cut since 1.2.0. Set semanticCommitType=fix so every dependency
update becomes fix(deps): -> patch. Only Renovate-authored commits are
retyped; hand-authored types are unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Mark major dependency updates as breaking (major releases)

**Files:**
- Modify: `renovate-presets/default.json` (`packageRules` array, insert as the FIRST element, currently starting at line 12 `"packageRules": [`)

**Interfaces:**
- Consumes: the mechanism decision from Task 1 (Option A `commitBody` vs. Option B repo-setting-then-A).
- Produces: major dependency updates carry `BREAKING CHANGE:`, which release-please maps to a major; consumers gate these via the existing `roleme/workflows` major rule.

- [ ] **Step 1: Insert the major-update rule as the first packageRule**

In `renovate-presets/default.json`, make the new rule the first element of `packageRules` (before the existing "Default for ALL managers" rule):

```json
    {
      "description": "Major dependency updates carry a BREAKING CHANGE footer so release-please cuts a MAJOR release of this shared repo. Consumers gate roleme/workflows majors manually (see the major rule below), so a possibly-spurious major is a one-click merge there, never a silent rollout. Non-major updates inherit semanticCommitType=fix -> patch.",
      "matchUpdateTypes": ["major"],
      "commitBody": "BREAKING CHANGE: major version bump of a dependency; review consumer compatibility."
    },
```

(If Task 1 selected Option B, you already patched the repo squash setting; the rule above is unchanged. There is no A′ variant to apply once the repo setting preserves commit messages.)

- [ ] **Step 2: Validate the preset still parses**

Run:
```bash
npx --yes --package renovate -- renovate-config-validator renovate-presets/default.json \
  || python3 -c "import json,sys; json.load(open('renovate-presets/default.json')); print('JSON OK')"
```
Expected: `INFO: Config validated successfully` (or `JSON OK`). No `ERROR` lines.

- [ ] **Step 3: Confirm rule ordering and that the three original rules remain**

Run:
```bash
python3 -c "import json; r=json.load(open('renovate-presets/default.json'))['packageRules']; print(len(r), 'rules'); print([x.get('description','')[:40] for x in r])"
```
Expected: `4 rules` and the first entry begins with `Major dependency updates carry a BREAKING`, followed by the three original descriptions (`Default for ALL managers…`, `Our own shared reusables…`, `roleme/workflows major bumps…`).

- [ ] **Step 4: Commit**

```bash
git add renovate-presets/default.json
git commit -m "feat: cut a major release on breaking dependency updates

Add a matchUpdateTypes:[major] rule with a BREAKING CHANGE commitBody so a
major dependency bump maps to a major release of this repo. Consumers gate
roleme/workflows majors manually, so an over-declared major is a one-click
merge, never a silent rollout. Squash-body verified (Task 1): <record option A or B>.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

Replace `<record option A or B>` with the Task 1 outcome.

---

### Task 4: (Optional, on user confirmation) Release the accumulated backlog

The three commits already on `main` since `1.2.0` (`refactor` #34, `chore(deps)` #30, `chore(deps)` #26) are not retroactively released. Only do this task if the user confirms they want them released now.

**Files:**
- None in this repo's tracked config; produces one empty commit on `main` after this PR merges.

**Interfaces:**
- Consumes: nothing.
- Produces: a `Release-As` commit that makes release-please open a `1.2.1` release PR covering the backlog.

- [ ] **Step 1: Confirm with the user**

Ask: "Release the 3 unreleased commits since 1.2.0 as 1.2.1 now?" Only proceed on yes.

- [ ] **Step 2: After this plan's PR is merged to main, push a Release-As commit**

On an up-to-date `main`:
```bash
git checkout main && git pull --ff-only
git commit --allow-empty -m "chore: release backlog since 1.2.0

Release-As: 1.2.1

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Then follow the repo's branch/PR rules (do not push directly to main — open a PR with this commit, or push via the normal flow if permitted).

- [ ] **Step 3: Verify release-please opens the 1.2.1 PR**

Run:
```bash
gh pr list --state open --search "release 1.2.1 in:title"
```
Expected: a `chore(main): release 1.2.1` PR exists.

---

## Self-Review

**Spec coverage:**
- Goal (non-breaking dep → patch): Task 2. ✓
- Goal (breaking dep → major): Task 3. ✓
- Hand-authored types unchanged: enforced by `semanticCommitType` semantics, noted in Global Constraints and Task 2. ✓
- Auto-major safe because consumers gate majors: relied on in Task 3 description; no code needed (existing rule 3). ✓
- Squash-body dependency: Task 1 verifies it. ✓
- Backlog note: Task 4 (optional, gated on user confirmation). ✓
- Validation (config validator + behavioral): Tasks 2/3 run the validator; behavioral check happens post-merge on the next Renovate PR. ✓

**Placeholder scan:** The only intentional fill-in is `<record option A or B>` in Task 3's commit message, resolved by Task 1's decision. No TBD/TODO/"handle edge cases".

**Type consistency:** N/A (no code types). Rule counts and descriptions are asserted exactly in Task 3 Step 3.

**Note on TDD:** This repo has no unit-test harness for the preset; the analogue of "failing test → pass" is the config validator plus the structural assertion in Task 3 Step 3, and the post-merge behavioral check. This is the correct verification for a config-only change.
