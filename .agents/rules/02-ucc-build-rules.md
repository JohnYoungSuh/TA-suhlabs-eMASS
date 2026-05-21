# Rule 02 — UCC Build Rules

## schemaVersion (CRITICAL — Issue 9)

- `globalConfig.json` `meta.schemaVersion` **MUST** be `"0.0.9"` or lower.
- UCC 6.1.0 allowlist: `{ "0.0.0" … "0.0.9" }` — `"0.0.10"` is **NOT** in it.
- If schemaVersion is outside the allowlist, UCC silently resets to `"0.0.0"` and
  re-runs ALL migration passes every build. The 0.0.10 migration then writes
  `"0.0.10"` back to the source file — creating an infinite loop that can strip
  tabs and pages from the output without any error or warning.
- After every build **verify tabs** in the compiled output:
  ```bash
  python3 -c "
  import json; d=json.load(open('output/TA-suhlabs-eMASS/appserver/static/js/build/globalConfig.json'))
  print([t.get('name') or t.get('type') for t in d['pages']['configuration']['tabs']])
  print('inputs:', 'EXISTS' if 'inputs' in d['pages'] else 'MISSING')
  "
  ```
- Expected tab order: `['account', 'output', 'proxy', 'loggingTab']`

## UCC Page Types (Issue 8)

- Supported top-level pages: `configuration`, `inputs`, `dashboard`.
- `"outputs"` is **NOT** a valid top-level page — UCC will error at build time.
- Output/write settings belong as a **tab inside `configuration`**.

## Build Workflow

```
make lint          # Validates globalConfig.json JSON is parseable
make build         # ucc-gen build + fix_ui.sh + cleanup
make validate      # Checks artifacts, version, JS count, python.required
```

- `make build` runs `fix_ui.sh` automatically — do not run `ucc-gen build` naked.
- `fix_ui.sh` saves/restores `globalConfig.json` around the UCC static asset copy.
- Never evaluate on build exit code alone — always run `make validate` after.

## UCC Version Pinning

- Authoritative version: `requirements.txt` (`splunk-add-on-ucc-framework==6.1.0`).
- `UCC_VERSION` in Makefile is **documentation only** — keep both in sync.
- After any UCC bump: run `make build && make validate` and re-inspect tabs/inputs.

## Version Bumping

- Single source of truth: `make bump VERSION=x.y.z`
- This updates Makefile `TA_VERSION`, `package/app.manifest`, and `globalConfig.json`
  `meta.version` atomically. **Never** hand-edit version strings in multiple files.
- `schemaVersion` is NOT the same as `meta.version` — do not confuse them.
- After `make bump`, re-check that `schemaVersion` is still `"0.0.9"`.

## Python.Required (AppInspect — Issue 5)

- Both `inputs.conf` and `restmap.conf` in the built output must contain
  `python.required = 3.13` in every modular-input / admin_external stanza.
- `fix_ui.sh` injects these if missing — but `package/default/inputs.conf` must
  also carry the stanza so UCC picks it up as a base.
- `make validate` asserts `python.required` is present in both files.

## Docker & Permissions (Issue 4 / Issue 6)

- Splunk Docker container writes `output/` files as `root`.
- `chmod -R u+w output/` silently fails on root-owned files (EPERM, swallowed by `|| true`).
- Correct fix: `sudo chown -R $(id -u):$(id -g) output/` then `rm -rf output/`.
- The Makefile `build` target already handles this automatically.
