# host/ — machine-level config

Copied, never stowed: these files live outside `$HOME` or on the Windows side.

| File | Destination | Applied by |
|---|---|---|
| `wsl.conf` | `/etc/wsl.conf` | `install.sh` step 2, when the Windows `PATH` leaks in; `wslconf-sync.zsh` (via `sync.sh`) copies it back |
| `work-wsl/.wslconfig` | `C:\Users\<user>\.wslconfig` | By hand on the Windows side, then `wsl --shutdown` |

Nothing here may identify corporate infrastructure; values stay in `~/.config/zsh/secrets`.
