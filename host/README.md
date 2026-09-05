# host/ — Machine-specific configuration templates

This directory contains templates for machine-specific config that **must not be committed**.

## Usage

Each subdirectory represents a machine profile. Copy the relevant template to your home directory:

```zsh
# Work WSL machine
cp ~/dotfiles/host/work-wsl/.zshrc.local ~/.zshrc.local
$EDITOR ~/.zshrc.local    # fill in your tokens, adjust paths
```

`~/.zshrc.local` is sourced automatically at the end of `~/.zshrc`. It is gitignored.

## Available profiles

| Profile | Description |
|---|---|
| `work-wsl/` | Windows WSL, company Jira/GitLab, project-specific aliases |

## What belongs here

- Company URLs (`JIRA_URL`, `GITLAB_API_URL`, etc.)
- API tokens and credentials → prefer `~/.zsh_secrets` (stored in Bitwarden)
- WSL/Windows-specific paths (`/mnt/c/...`)
- `$KUBECONFIG` variants per environment
- Project-specific aliases (`pet`, `hinst`, `hupd`, etc.)
- Anything that differs between machines or reveals internal infrastructure
