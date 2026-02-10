# Git Start Work Reference

## Purpose

Use this guide to create a ticket branch in a cross-platform, Git-only way.

## Defaults

- Base branch: `development`
- If `origin/development` is missing, ask the user for the base branch name.

## Standard Flow (Clean Worktree)

```bash
git status
git fetch --prune origin
git switch development
git pull --ff-only origin development
git switch -c <branch-name>
```

If `git switch` is unavailable, use:

```bash
git checkout development
git pull --ff-only origin development
git checkout -b <branch-name>
```

## Dirty Worktree Options

Choose one of the following before switching branches:

1) Commit your changes to the current branch.

2) Stash your changes and restore later:

```bash
git stash push -m "wip: <reason>"
git stash pop
```

3) Abort and return when your worktree is clean.

## Existing Branch Scenarios

- Local branch exists:

```bash
git switch <branch-name>
```

- Remote-only branch exists:

```bash
git switch --track origin/<branch-name>
```

Fallback:

```bash
git checkout -t origin/<branch-name>
```

## Push and Track the Branch

```bash
git push -u origin <branch-name>
```

## Best Practices

- Keep branches short-lived and focused on one ticket.
- Include the ticket key in the branch name.
- Avoid rewriting shared history and force pushes.
- Prefer `git pull --ff-only` for the base branch.
- Sync the base branch before creating your feature branch.
- Verify your current branch with `git status` or `git branch --show-current`.

## References

- https://git-scm.com/docs/git-switch
- https://git-scm.com/docs/git-pull
- https://git-scm.com/docs/git-stash
- https://www.atlassian.com/git/tutorials/using-branches
