# Branch protection

Lock `main` so changes arrive only via pull request with CI green.

`CHECK` is the required check's job name as it shows in the Checks tab. Omit
`required_status_checks` if the repo has no CI.

```sh
REPO="owner/name"
CHECK="zizmor"

gh api "repos/$REPO/branches/main/protection" > protection-before.json

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

`PUT` replaces the whole object — omitted fields are turned off.

Toggle admin enforcement alone:

```sh
gh api -X POST   "repos/$REPO/branches/main/protection/enforce_admins"   # on
gh api -X DELETE "repos/$REPO/branches/main/protection/enforce_admins"   # off
```

Revert:

```sh
gh api -X PUT "repos/$REPO/branches/main/protection" --input protection-before.json
gh api -X DELETE "repos/$REPO/branches/main/protection"   # or remove entirely
```

Keep `required_approving_review_count` at `0` in a solo repo — `1` locks you out
of your own `main`.
