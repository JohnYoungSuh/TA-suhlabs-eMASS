---
trigger: always_on
---

# Project Workflow Rules

## Standard Development Loop
Every configuration or code change must follow this sequence:
1. **Edit** source files in `package/` or config in `globalConfig.json`.
2. **Build**: Run `make build` to run the UCC generator and clean up assets.
3. **Validate**: Run `make validate` to verify built files, paths, JS bundle counts, and `python.required` injection.
4. **Test**: Run `make test-smoke` or deployment checks to verify the functionality of inputs and REST handlers.
5. **Commit**: Commit changes using Conventional Commits.

## Release Checklist (Version Bump)
When bumping the version, update all 3 versions atomically:
1. `Makefile` — `TA_VERSION = x.y.z`
2. `package/app.manifest` — `info.id.version = x.y.z`
3. `globalConfig.json` — `meta.version = x.y.z`

Always verify that `schemaVersion` remains `"0.0.9"`.
Commit message: `chore: bump version to X.Y.Z across all configs`

## Build Commands Reference

| Task | Command |
|---|---|
| Prepare dev environment (pip, venv) | `make setup` |
| Verify basic requirements | `make preflight` |
| Build add-on with UCC | `make build` |
| Verify output directory structure | `make validate` |
| Build Splunk docker image | `make image` |
| Local docker compose smoke test | `make test-smoke` |
| Bump versions | `make bump VERSION=x.y.z` |
| Package `.tar.gz` for upload | `source .venv/bin/activate && ucc-gen package --path output/TA-suhlabs-eMASS` |
| Clean build artifacts | `make clean` |

## Lockfile Policy
- **Do NOT delete `package-lock.json`** or `requirements.txt` locks unless necessary.
- Drive all package upgrades through `requirements.txt` updates, and run `make setup` to apply them.
