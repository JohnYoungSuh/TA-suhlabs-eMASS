---
trigger: always_on
---

# Hard Constraints: Things I Must Never Do

## Code Safety
- **NEVER use invalid restmap.conf keys** — only standard keys (`handlerfile`, `handleractions`, `match`, `members`) are allowed.
- **NEVER use globalConfig.json schemaVersion > "0.0.9"** — using `"0.0.10"` or higher causes UCC to strip configuration tabs silently.
- **NEVER hardcode secrets, API keys, or eMASS credentials** in any source file.
- **NEVER include custom Mako templates** under `appserver/templates/` or `appserver/modules/`.
- **NEVER commit `.venv/`, `output/`, or generated `.tar.gz` packages** to Git.

## Build & Release
- **NEVER push a version bump without running `make build` and `make validate`**.
- **NEVER package or release without verifying that at least 20 JS files exist in the output** and that `python.required` is injected into `inputs.conf` and `restmap.conf`.
- **NEVER package version bumps without synchronizing Makefile `TA_VERSION`, `package/app.manifest` `info.id.version`, and `globalConfig.json` `meta.version`**.

## Environment
- **NEVER use PowerShell or Windows CMD** — all commands must run in WSL2/bash with UNIX paths.
- **NEVER use Windows drive-letter paths** (e.g., `C:\Users\...`) — use `/home/suhlabs/...`.
- **NEVER attempt to install or configure Docker inside WSL** — Docker runs on Windows via Docker Desktop. If `docker` commands fail, stop and ask the user to start Docker Desktop on the Windows host.

## Behavior
- **NEVER retry a failing task more than 3 times** — stop and ask the user on the 3rd failure.
- **NEVER make breaking architectural changes** (such as reversing Salesforce-style account configuration or removing checkpointing) without explicit user approval.
