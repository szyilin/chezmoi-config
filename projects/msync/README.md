msync
=====

Personal CLI (Rust) to sync/upload local build artifacts to servers using
config-driven rsync. Designed to keep workflows keyboard-only with profile-based
paths and optional tab completion.

Planned capabilities (initial draft):
- Read profiles (src/dst/flags) from a config file.
- `msync upload -u <profile>` for one-command uploads; overrides for ad-hoc src/dst.
- Progress output via rsync; optional dry-run, include/exclude, delete.
- Shell completion generation (zsh/bash/fish).
