# Branch protection

How to lock `main` so every change arrives via a pull request with CI green.
Written as a recipe: set `REPO` and run it against any repo you admin.

## The trap: `enforce_admins`

Protection **does not apply to repo admins** unless `enforce_admins` is `true`.
This repo had a required `zizmor` check for a long time while admins could still
push straight to `main` — the API reported protection as enabled, but in
practice nothing was enforced, and a config comment in
`renovate-presets/default.json` had drifted to claim the repo had no protection
at all.

If you are the only person working in a repo, `enforce_admins: false` means your
protection does nothing. Check it first:

```sh
REPO="owner/name"
gh api "repos/$REPO/branches/main/protection" \
  --jq '"admins=\(.enforce_admins.enabled) reviews=\(.required_pull_request_reviews) checks=\(.required_status_checks.contexts)"'
```

## Before you change anything

Save the current state so you can revert:

```sh
REPO="owner/name"
gh api "repos/$REPO/branches/main/protection" > protection-before.json
```

A 404 here means no protection exists yet — that is fine, there is just nothing
to revert to.

## Apply

`CHECK` is the *job name* of a required status check as it appears in the Checks
tab (here: `zizmor`). Drop `required_status_checks` entirely if the repo has no
CI yet — a required check that never reports will block every merge.

```sh
REPO="owner/name"
CHECK="zizmor"

cat > protection.json <<JSON
{
  "required_status_checks": { "strict": true, "contexts": ["$CHECK"] },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "restrictions": null
}
JSON

gh api -X PUT "repos/$REPO/branches/main/protection" --input protection.json
```

`PUT` replaces the whole protection object, so every field you want to keep must
be present in the payload. Omitting a field turns it off.

### What each field does

| Field | Effect |
| --- | --- |
| `required_pull_request_reviews.required_approving_review_count: 0` | A PR is required, but no approval click is needed. This is what makes solo repos workable — without the block entirely, direct pushes are allowed. |
| `required_status_checks.contexts` | These checks must pass before merge. |
| `required_status_checks.strict: true` | The branch must be up to date with `main`. Expect `BEHIND` on open PRs whenever something lands; fix with `gh pr update-branch <n>`. |
| `enforce_admins: true` | Applies all of the above to admins. Without it, the rest is advisory for you. |
| `restrictions: null` | No per-user/team push allowlist. |

`enforce_admins` can also be toggled on its own, without re-sending the whole
object:

```sh
gh api -X POST   "repos/$REPO/branches/main/protection/enforce_admins"   # on
gh api -X DELETE "repos/$REPO/branches/main/protection/enforce_admins"   # off
```

## Verify

Do not trust the API readback alone, and do not trust `git push --dry-run` — a
dry run reports success even when protection would reject the push, because it
does not exercise the server-side hook. Test with a real push:

```sh
git commit --allow-empty -m "protection probe"
git push origin main
```

Expected:

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - Changes must be made through a pull request.
remote: - Required status check "zizmor" is expected.
 ! [remote rejected] main -> main (protected branch hook declined)
```

The push is rejected, so nothing reaches the remote — but the commit is still on
your local branch. Clean it up:

```sh
git reset --hard origin/main
git rev-parse HEAD origin/main   # confirm both SHAs match
```

## Revert

```sh
gh api -X PUT "repos/$REPO/branches/main/protection" --input protection-before.json
```

Or remove protection completely:

```sh
gh api -X DELETE "repos/$REPO/branches/main/protection"
```

## Living with it

- Hotfixes need a PR too. To bypass: toggle `enforce_admins` off, push, toggle
  it back on — and remember the second step.
- Bot PRs (Renovate, release-please) must satisfy the same rules. With 0
  required approvals they merge unattended, but their checks must genuinely
  pass, and `strict: true` means they may need a branch update first.
- `required_approving_review_count: 1` in a solo repo locks you out of your own
  `main`: nobody else can approve, and you cannot approve your own PR. Keep it
  at 0 unless someone else can review.
