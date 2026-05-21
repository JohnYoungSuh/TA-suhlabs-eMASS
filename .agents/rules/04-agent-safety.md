# Rule 04 — Agent Behaviour & Safety

## Before Making Any Changes

1. **Read LESSONS_LEARNED.md** — 1400+ lines of hard-won gotchas. Every section
   has `Issue N:` headers. Search for the relevant issue before attempting any fix.
2. **Read check_config.py output** (or run it) to see current schemaVersion + tabs
   state before and after every build.
3. **Never trust build exit codes alone** — silent failures are the norm here
   (UCC copies files without errors, patcher regex misses stanzas silently, etc.).

## Files That Must NOT Be Deleted or Overwritten Without Review

| File | Why |
|---|---|
| `globalConfig.json` | UCC source; losing proxy/input tabs requires full re-auth |
| `package/bin/emass_poam.py` | Input with checkpointing — complex, tested |
| `package/bin/emass_poam_output.py` | Output modular script |
| `CHECKPOINTING_IMPLEMENTATION.md` | Backup reference if bin/ ever lost again |
| `LESSONS_LEARNED.md` | Institutional memory — append, never truncate |
| `fix_ui.sh` | Critical post-build patcher — changes break inputs/proxy UI |
| `.agents/rules/` | This rules directory |

## When Editing globalConfig.json

- ✅ Always verify `schemaVersion` is `"0.0.9"` after any edit.
- ✅ Run `make build && make validate` after any change.
- ✅ Inspect tabs in compiled output (see rule 02).
- ❌ Never let `make bump` run without verifying schemaVersion was not changed.

## LESSONS_LEARNED.md Maintenance

- **Append only** — never rewrite existing issue entries.
- Format: `## Issue N: <title>` → Problem → Root Cause → Resolution → Lesson Learned
- Update `Document Version` and `Last Updated` at the bottom.
- New sessions go under a `## Session: YYYY-MM-DD — <topic>` header.

## Debugging Hierarchy

When something breaks:

1. Check `schemaVersion` in `globalConfig.json` (most common silent killer).
2. Run `make validate` and read JSON error output carefully.
3. Inspect compiled `globalConfig.json` tabs (not the source).
4. Check `fix_ui.sh` patcher output — stanza patterns must match actual conf format.
5. Check `requirements.txt` UCC version vs installed `pip show splunk-add-on-ucc-framework`.
6. Only then debug application logic.

> **Mantra: Verify infrastructure assumptions before debugging application logic.**

## Commit Discipline

- Commit `globalConfig.json` after every build that produces a working Splunk UI.
- Commit message format: `feat:` / `fix:` / `chore:` + short description.
- Keep `package/default/inputs.conf` tracked in git — it's a source file, not generated.
- `output/` is generated — it is in `.gitignore` (do not force-add).
