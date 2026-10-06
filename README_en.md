# UniqueBash

Chinese: [README.md](README.md)

## Overview
UniqueBash is an extensible collection of **mksh** configuration modules for general Linux distributions. It aims to provide an out-of-the-box, customizable shell experience. Modules include prompt, aliases, env, functions and more. Config files live in the `mkshrc.d` directory and install as `~/.mkshrc`.

This project evolved from the author's personal shell setup used on development boards (e.g. Milk-V Duo S); it is now modularized, fully ported from Bash to mksh, and packaged for reuse. Feedback and contributions are welcome.

> **Requirements**: mksh (verified on R59); `git` (optional — prompt Git status and 3-way merge updates); `dialog` / `fzf` (optional, only for `--tui` module selection).

## Features
- **Modular**: every setting lives in its own file under `mkshrc.d/`, decoupled and easy to replace or extend.
- **Dual prompt styles**: Powerline (colored arrows) and 8-color ASCII, switchable at runtime with `Ctrl-p`; defaults to ASCII on TTY. The prompt is built by a `${| ... ; }` value-replacement hook in PS1 — mksh's equivalent of `PROMPT_COMMAND`.
- **Git status**: branch, staged/unstaged/untracked counts, conflicts, and ahead/behind commits, with a 3-second cache (skips `git` when the directory is unchanged).
- **Pipeline error display**: any failed segment is shown in red — e.g. `true | false | true` prints `✕0|1|0` instead of only the last exit code.
- **Directory stack**: mksh has no built-in `pushd` / `popd` / `dirs`, so `interactive.startup` provides bash-compatible implementations (including `+n` / `-n` rotation and `dirs +n` / `dirs -n` lookups). `cd +n` / `cd -n` and bare digits (`0`-`9`) jump through the stack.
- **History**: saved to `~/.mksh_history`; duplicate lines and lines starting with whitespace are ignored automatically (same as `HISTCONTROL=ignoreboth`).
- **Command-not-found hints**: `command_not_found_handle` keeps the multi-language (zh/en/es) messages and the "did you mean XXX?" suggestion, but mksh never calls that hook; the "bare number jumps the directory stack" behaviour is instead implemented directly by the `0`-`9` functions.
- **App integration**: auto-wires `thefuck`, `memo`, etc. when available.

## Quick Start
```sh
./setup.sh
```
> Note: existing `~/.mkshrc` and `~/.profile` are backed up automatically; the default is a **full install with no questions** (use `--tui` / `--select` / `--modules` to pick modules).

## Install Options

`setup.sh` uses a **subcommand** structure (the default subcommand is `install`). Legacy flags (`--update` / `--uninstall` / `--preview` / `--tui` / `--yes` / `--force` / `--help` / `--version`) are still accepted as aliases.

```sh
./setup.sh [subcommand] [options]

Subcommands:
  install        back up + symlink ~/.mkshrc and ~/.profile, install modules (default)
  update         repair symlinks, 3-way merge modules (skip *.local.*)
  uninstall      restore ~/.mkshrc / ~/.profile from backups, remove default modules
  status         show install state, symlink targets, module drift, pending conflicts
  preview [act]  dry-run any action (install/update/uninstall), write nothing
  help / version help / version

Options:
  --yes, --auto          non-interactive (default is already a full install)
  --tui                  pick modules with a TUI (dialog / fzf)
  --select               pick modules with numbered prompts
  --modules=a,b,c        pick modules by name, non-interactively
  --no-backup            do not back up ~/.mkshrc / ~/.profile
  --overwrite-modules    overwrite your edited modules with the repo version
  --force                legacy alias = --no-backup + --overwrite-modules
  --lang=zh|en           UI language (default follows your locale; fully bilingual)
  --preview              dry-run the current action (write nothing)
```

Exit codes:

| Code | Meaning |
| --- | --- |
| 0 | success |
| 1 | fatal error (I/O, git failure, …) |
| 2 | usage error (unknown subcommand/option) |
| 3 | preflight failure (missing `main.mkshrc`, sourced instead of run, …) |
| 4 | finished with merge conflicts (install/update) |
| — | `status` subcommand: 0 OK / 1 problems (broken symlink, pending conflicts) |

```sh
./setup.sh                      # full install, no questions, auto backup
./setup.sh --select             # pick modules by number
./setup.sh update               # everyday update
./setup.sh preview update       # dry-run an update
./setup.sh status               # show install status
./setup.sh uninstall --yes      # non-interactive uninstall
./setup.sh --lang=zh help       # Chinese help
```

Default behavior:
1. Back up `~/.mkshrc` to `~/.mkshrc.bak.<timestamp>` and symlink it to this repo's `main.mkshrc` (no repeated backup when the symlink is already correct).
2. Back up `~/.profile` to `~/.profile.bak.<timestamp>` and symlink it to `startup.profile`.
3. Copy `mkshrc.d/*` into `~/.mkshrc.d/` (existing files are backed up first).
4. Write the state file `~/.mkshrc.d/.install_state` (version, time, repo commit, installed modules, last action, pending conflicts) for `status` and `ub-status`; the legacy `.repo_root` / `.last_update` are still written so `ub-*` keeps working.

> **Updating (keeps your edits)**: the `update` subcommand (or `--update`) uses a 3-way diff-merge (your version / base version / upstream version). The rules:
> - **Repo added a new file**: installed into your `~/.mkshrc.d/`; your existing files are untouched.
> - **You didn't edit a file, but the repo did**: updated directly to the upstream version (detected when your file contains no lines absent from upstream — i.e. it is a subset of upstream, which also covers "you had an older version and the repo evolved").
> - **You and the repo edited different parts of the same file**: `git merge-file` merges automatically — **your edits are kept and the repo's additions are also applied**.
> - **You and the repo edited the same line (real conflict)**: your working version is kept (so the shell keeps working), and the conflicting merge result with `<<<<<<<` markers is written to `~/.mkshrc.d/.merged_<file>` for you to resolve manually; your previous version is backed up to `~/.mkshrc.d/.backups/`.
> - **`*.local.*` files**: always skipped — no merge happens at all (they are your fully private config).
>
> Your version is backed up to `~/.mkshrc.d/.backups/` before merging. Day-to-day updates can simply use `ub-update` (see below).
> **Uninstalling**: the `uninstall` subcommand (or `--uninstall`) restores `~/.mkshrc` / `~/.profile` from the install-time backups and removes the default modules installed by this project (restoring your edited version if you had one), keeping `*.local.*` files.
> **Previewing**: any action can be rehearsed first with `preview` (e.g. `./setup.sh preview update`); the preview runs through the exact same code path as the real action and never writes to disk.

## Update Tools (in interactive shells)
After installing/updating, `func.mkshrc` provides:
- `ub-update` — same as `./setup.sh update` (auto-locates the repo).
- `ub-status` — module count, installed version / last action / repo commit (from `.install_state`), last update time, merge conflicts, and a pointer to the detailed status command.
- `ub-diff` — show per-file diffs between your `~/.mkshrc.d/` and the upstream repo.
- For a full check (symlinks pointing at this repo, module drift, pending conflicts) run `./setup.sh status` (exit code 1 when problems exist, so it is scriptable).

## Repository Structure
- `main.mkshrc`: main entry (the loader for `~/.mkshrc`); it loads `interactive.startup` and the `mkshrc.d` modules, and guards itself so it only runs under mksh and only once. **The prompt implementation (colors, Git parsing, rendering) lives in `mkshrc.d/prompt.mkshrc`** for easier maintenance.
- `startup.profile`: login-shell startup file (`~/.profile`) chaining `/etc/profile`, `/etc/mkshrc` (if present), and this config.
- `mkshrc.d/`: module directory; default files include:
  - `aliases.mkshrc` — command aliases (auto-detects `eza` / GNU `ls` / BSD `ls`)
  - `apps.mkshrc` — app integrations (e.g. `thefuck`)
  - `env.mkshrc` — environment variables (PATH, pager, locale-aware language)
  - `func.mkshrc` — user functions (`mkcd`, `command_not_found_handle`, `ub-*` update tools, …)
  - `interactive.startup` — interactive-only settings (history, directory stack, key bindings, prompt hook notes)
  - `memo.mkshrc` — personal memos (if `~/.memo` exists)
  - `prompt.mkshrc` — prompt core (colors, Git status parsing, Powerline/ASCII rendering and style toggle)

## Keybindings Quick Reference
The following keybindings are active in interactive shells (see `mkshrc.d/interactive.startup`):

| Key | Function |
| --- | --- |
| `Ctrl-p` | Toggle prompt style (Powerline ↔ ASCII, via a macro that runs `ptoggle`) |
| `Alt + Enter` | Insert a literal newline into the current input line |
| `Tab` | Complete the common prefix and list candidates (`complete-list`) |
| `Shift + Tab` | List candidates only (`list`) |
| `PgUp` / `PgDn` | Prefix history search (`search-history-up` / `search-history-down`, mksh defaults) |
| `Ctrl-r` | Incremental history search (`search-history`) |
| `cd +n` / `cd -n`, `pushd` / `popd` / `dirs` | Directory-stack jump and inspection |
| `0` - `9` | Jump to directory stack entry n |

**mksh limitations (differences from the previous Bash version)**:
- `bind` only accepts key sequences up to 3 bytes, so `Alt+↑` / `Alt+↓` (`\e[1;3A`, 6 bytes) cannot be bound; mksh also has no substring history search — use `PgUp` / `PgDn` or `Ctrl-r` instead.
- mksh has no readline `menu-complete`, so Tab does not cycle candidates, and there is no `completion-ignore-case`, `colored-stats`, or other `bind 'set ...'` option. mksh's built-in equivalents: directories get a trailing `/`, hidden files require a leading `.`, and overlong lines scroll horizontally.
- `Ctrl-p` is implemented as a `bind -m` macro (it types ` ptoggle` and presses Enter); the leading space keeps that line out of history.

Note: these keybindings and settings apply only to interactive shells. To view or modify them, edit `mkshrc.d/interactive.startup`.

## Extensibility Tips
- Put personal changes in new files inside `mkshrc.d` to avoid modifying defaults and simplify upstream updates.
- Use a naming convention like `XX.local.mkshrc` for machine/user-specific configuration and add them to `.gitignore`.
- To upgrade default modules run `./setup.sh update`; to fully remove run `./setup.sh uninstall`.

## Development & Linting
- A `.shellcheckrc` is provided at the repo root. shellcheck does not know the mksh dialect, so check it as bash:
  ```sh
  shellcheck -s bash setup.sh main.mkshrc mkshrc.d/*.mkshrc mkshrc.d/interactive.startup
  ```
- After editing, verify syntax with `mksh -n <file>`.

## Contributing
Please open issues or PRs; discuss major design changes in an issue first.

## License
See the `LICENSE` file at the repository root.

---

For the Chinese version, click the link at the top: [README.md](README.md)
