# Release Notes: TA-suhlabs-eMASS v1.0.3

**Release Date:** 2026-04-27
**UCC Framework Version:** 6.1.0

## Overview
Version 1.0.3 is a critical security and compliance release focused on passing the new mandatory Splunk Cloud Vetting requirements (April 2026 standards). It also includes significant hardening of the local build and CI/CD pipeline.

## Security & Compliance
- **Splunk Cloud Vetting Compliance**: Added the mandatory `python.required = python3` directive across all Python REST handlers (`restmap.conf`) and Modular Inputs (`inputs.conf`). This explicitly satisfies the `check_admin_external_restmap_conf_python_required` and `check_modular_inputs_python_required` AppInspect checks.

## Enhancements
- **UCC Framework Upgrade**: Upgraded the underlying `splunk-add-on-ucc-framework` dependency from `6.0.1` to `6.1.0` to natively support the latest Splunk configuration generation standards.
- **Build Pipeline Hardening**:
  - **Version Synchronization**: Centralized the application version (`1.0.3`) into a single source of truth (`TA_VERSION`) to prevent drift between the build outputs, CI validation, and AppInspect.
  - **Permission Handling**: Streamlined Docker-to-WSL volume permissions. The build process now intelligently manages root-owned artifact cleanup without triggering unnecessary `sudo` password prompts during standard local development.
  - **Strict Validation**: Upgraded the `make validate` CI gate to strictly assert the presence of `python.required` in all output configurations prior to packaging.

## Bug Fixes
- **Build Loop Guard**: Fixed a false-positive in the `Makefile` validation that incorrectly flagged deep vendor dependencies (like `grpc`/`protobuf` which contain directories named "output") as recursive build loops.

---

*Note: This package was built and verified using `zip_ta.sh` and is ready for Splunkbase submission.*
