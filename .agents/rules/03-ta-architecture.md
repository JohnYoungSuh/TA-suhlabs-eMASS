# Rule 03 — Splunk TA Architecture

## File Layout

```
project-root/
├── globalConfig.json        ← UCC source of truth for all UI (tabs, inputs, config)
├── Makefile                 ← Single entry point: lint, build, validate, bump
├── fix_ui.sh                ← Post-build patcher (UI files + python.required)
├── requirements.txt         ← pip pins — authoritative for UCC and dep versions
├── package/
│   ├── app.manifest         ← Splunkbase metadata (version synced by make bump)
│   ├── bin/
│   │   ├── emass_poam.py           ← Modular input (collect)
│   │   └── emass_poam_output.py    ← Modular output (POST/PUT to eMASS)
│   ├── default/
│   │   └── inputs.conf      ← Base stanza: python.version + python.required
│   └── README/
│       └── inputs.conf.spec ← Splunkbase spec file for the input
└── output/
    └── TA-suhlabs-eMASS/    ← Generated build — do NOT hand-edit
```

## globalConfig.json Sections

| Section | Purpose |
|---|---|
| `pages.configuration.tabs[name=account]` | eMASS credentials & index |
| `pages.configuration.tabs[name=output]` | POST/PUT output settings |
| `pages.configuration.tabs[type=proxyTab]` | Proxy (built-in UCC tab) |
| `pages.configuration.tabs[type=loggingTab]` | Log level (built-in UCC tab) |
| `pages.inputs` | Modular input configuration UI |

- `proxyTab` and `loggingTab` use **`type`** not **`name`** — validators differ.
- The `inputs` page drives the Inputs nav item in Splunk Web.

## Checkpointing Pattern (Issue 9 from LESSONS_LEARNED)

```python
from solnlib.modular_input import checkpointer

ckpt = checkpointer.KVStoreCheckpointer(
    "ta_suhlabs_emass_emass_poam", session_key, "TA-suhlabs-eMASS"
)
checkpoint_key = f"{input_name}_last_collection"
last_time = ckpt.get(checkpoint_key)          # None on first run
poams = collect_filtered(api_url, last_time)  # API + client-side filter
write_events(poams)
ckpt.update(checkpoint_key, current_time)     # Only update on success
```

- Update checkpoint **only after** events are successfully written to Splunk.
- Filter by multiple date field names (APIs are inconsistent):
  `lastModifiedDate`, `last_modified_date`, `updatedDate`, `modifiedDate`

## restmap.conf Stanzas

Valid keys only:
- `handlerfile`, `handleractions`, `match`, `members`
- ❌ Do NOT add `handlertype` or `handlerpersistentmode` (not valid, IDE will flag them)

## Splunkbase Packaging

```bash
make build
make validate
source .venv/bin/activate && ucc-gen package --path output/TA-suhlabs-eMASS
```

Creates `TA-suhlabs-eMASS-<version>.tar.gz` at project root.
Test in a clean Splunk instance before uploading.
