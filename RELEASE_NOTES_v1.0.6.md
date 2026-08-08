# Release Notes: TA-suhlabs-eMASS v1.0.6

**Release Date:** 2026-08-07
**UCC Framework Version:** 6.5.2

## Overview
Version 1.0.6 is a maintenance and compatibility release that upgrades the UCC framework to version 6.5.2, officially declares compatibility with Splunk 10.x (dropping 9.x), adds standard Splunk app icons, and cleans up deprecated custom Mako templates to ensure complete AppInspect compliance.

## New Features
- **Splunk 10.x Compatibility**: Official compatibility declared for Splunk 10.x. Docker and demo configurations have been updated to use the latest Splunk versions. Compatibility with Splunk 9.x has been dropped.
- **Splunk App Icons**: Integrated standard Splunk application icons (`appIcon.png` and `appIcon_2x.png`) under both `package/appserver/static/` and `package/static/` to ensure visual presence in launcher and apps lists.
- **GitHub Dependabot**: Enabled automated dependency tracking and security alerts via Dependabot.

## Bug Fixes & Hardening
- **AppInspect Compliance (Mako Templates)**: Deleted deprecated custom HTML template `package/appserver/templates/base.html` to guarantee clean AppInspect vetting with zero custom Mako templates.
- **Agent Rules Alignment**: Standardized engineering constraints and project rules in `.agents/rules/` for developer tooling consistency.
- **zip_ta.sh — Exclusion Hardening**: Enhanced packaging exclusions to prevent packaging volume-mounted `default.old.*` stanzas.

## Dependency Updates
- Upgraded `splunk-add-on-ucc-framework` from `6.1.0` to `6.5.2`.

## Upgrade Notes
- Rebuild and repackage required: `make build && make zip`
- No configuration schema changes or migration steps are needed.

## Verified On
- Splunk Enterprise: 10.x (Latest)
- UCC Framework: 6.5.2
- Python: 3.12 / 3.13
- AppInspect: 0 errors, 0 warnings
