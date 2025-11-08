# Lessons Learned: TA-securepro-eMASS Demo Video & Data Ingestion

**Session Date:** November 8, 2025
**Branch:** `claude/emass-demo-video-011CUsZtcRkj8i1WEysgYprC`
**Outcome:** ✅ Successful - Data flowing into Splunk, all components working

---

## Executive Summary

Started with goal: Create demo video without watermarks showing eMASS data ingestion.

**Major Discovery:** The add-on had a **missing inputs UI page** and **broken modular input** that prevented data collection entirely. Fixed foundational issues before demo video creation became possible.

**Final Result:**
- ✅ Working inputs UI for creating data collection
- ✅ Data successfully ingesting into Splunk
- ✅ Automated demo framework created (Playwright-based)
- ✅ Comprehensive cleanup and rebuild scripts

---

## Critical Issues Found & Fixed

### 1. Missing Inputs Page in globalConfig.json (CRITICAL)

**Problem:**
```json
// globalConfig.json only had:
"pages": {
  "configuration": {...}  // Only account configuration
  // NO inputs page!
}
```

**Impact:**
- Users could create accounts but NOT create data inputs
- No way to start data collection via UI
- Inputs had to be manually created in .conf files

**Root Cause:**
UCC `globalConfig.json` was incomplete. Only had configuration page, missing the entire inputs page definition.

**Fix:**
```json
"pages": {
  "configuration": {...},
  "inputs": {              // ADDED
    "services": [...],
    "table": {...}
  }
}
```

**Lesson:** Always verify BOTH configuration AND inputs pages exist in UCC add-ons. Without inputs page, there's no way to create data collection through the UI.

---

### 2. Modular Input Initialization Errors (CRITICAL)

**Problem 1: Internal Arguments Defined in Scheme**
```
ERROR: Endpoint argument "index" is an internal argument that is
handled specially within Splunk, and it should not be defined via introspection
```

**Root Cause:**
`emass_poam.py` explicitly defined Splunk's internal arguments:
```python
scheme.add_argument(smi.Argument('name', ...))      # ❌ Internal
scheme.add_argument(smi.Argument('interval', ...))  # ❌ Internal
scheme.add_argument(smi.Argument('index', ...))     # ❌ Internal
```

**Fix:**
```python
# Only define CUSTOM arguments
# Splunk provides name, interval, index automatically
scheme.add_argument(smi.Argument('account', ...))   # ✅ Custom only
```

**Lesson:**
- Splunk provides `name`, `interval`, `index`, `sourcetype` automatically to ALL modular inputs
- **NEVER** define these in `get_scheme()`
- Only define custom parameters your input needs
- They're still accessible in `stream_events()` via `input_item.get("interval")`

**Why This Matters:**
Without this fix, the modular input couldn't even initialize, making data collection impossible.

---

### 3. Missing Authentication Header (user-uid)

**Problem:**
```python
headers = {
    "api-key": api_key,
    "Accept": "application/json"
}
# Missing user-uid header!
```

API returned 401 Unauthorized.

**Root Cause:**
Some eMASS deployments require BOTH headers:
- `api-key`: API key
- `user-uid`: User identifier

Our implementation only sent api-key.

**Fix:**
1. Added `user_uid` field to account configuration (globalConfig.json)
2. Updated Python code to send header when provided:
```python
if user_uid:
    headers["user-uid"] = user_uid
```

**Lesson:**
- Always verify API authentication requirements against actual deployment
- Test with curl first to confirm headers needed
- Make optional auth fields truly optional (not required)
- Document which eMASS deployments need which headers

---

### 4. UCC Table Structure (Input Page)

**Problem:**
Initially placed `table` inside each service:
```json
"services": [
  {
    "name": "emass_poam",
    "table": {...},     // ❌ WRONG LOCATION
    "entity": [...]
  }
]
```

UCC validation error: `'table' is a required property`

**Root Cause:**
Misunderstood UCC schema. Table must be at inputs PAGE level, not service level.

**Fix:**
```json
"inputs": {
  "services": [{...}],
  "table": {...}        // ✅ CORRECT LOCATION
}
```

**Lesson:**
- Reference working examples (Salesforce TA globalConfig.json)
- UCC schema: inputs page can have MULTIPLE services, but ONE table displays them all
- Table is shared across all services in the inputs page

---

### 5. WSL + Docker Desktop Environment

**Challenges:**
- Docker containers run in Docker Desktop (Windows), not WSL
- Playwright needs headless mode (no display in WSL)
- Network access between WSL and Docker containers
- File path mapping between WSL and Windows

**Solutions Implemented:**
1. Created `run_demo_wsl.sh` - WSL-specific demo runner
2. Always use `--headless` flag for Playwright
3. Network: `emass-net` external network connects containers
4. File paths: Document both WSL paths and Windows Explorer paths (`\\wsl$\...`)

**Lesson:**
- WSL is NOT Linux - Docker runs separately via Docker Desktop
- Always test networking: WSL → Docker containers
- Provide clear path mapping for users (WSL ↔ Windows)
- Headless mode is mandatory for WSL automation

---

## What Worked Well

### 1. Automated Rebuild Script (`rebuild.sh`)
```bash
#!/bin/bash
git pull
sudo rm -rf output/
make build
docker compose down -v
docker compose build --no-cache
docker compose up -d
sleep 30
docker logs -f splunk-emass | grep -i emass
```

**Why It Works:**
- One command rebuilds everything
- Clean state every time
- Immediate feedback via logs
- Saves repetitive typing

**Lesson:** Create automation scripts early for common workflows.

---

### 2. Using Working Examples

Requested working `globalConfig.json` from Salesforce TA.

**Before:** Guessing at UCC structure, trial and error
**After:** Clear pattern, fixed immediately

**Lesson:**
- Don't reinvent the wheel
- Official Splunkbase add-ons are great references
- Compare your structure to working examples
- UCC documentation is sparse - examples are better

---

### 3. Incremental Debugging

Approach used:
1. Fix modular input initialization FIRST (removed internal args)
2. THEN test authentication (added user_uid)
3. THEN verify data ingestion
4. FINALLY work on demo video

**Why This Worked:**
- Each layer builds on previous
- Clear separation of concerns
- Easier to identify what broke

**Lesson:**
- Fix foundation before building features
- Backend must work before UI matters
- Data ingestion before demo videos

---

## What Didn't Work

### 1. Dynamic Field Population (`modifyFieldsOnValue`)

**Attempted:**
```json
"modifyFieldsOnValue": [{
  "fieldsToModify": [{
    "fieldId": "index",
    "value": "{{account.index}}"  // ❌ Doesn't work
  }]
}]
```

**Result:** Literal string `{{account.index}}` appeared in UI dropdown

**Root Cause:** UCC doesn't support template variables from referenced entities

**Lesson:**
- Backend code can handle defaults (already does!)
- Not every UI feature needs frontend implementation
- Sometimes simpler is better

---

### 2. Initial Demo Script (Wrong Selectors)

**Problem:** Playwright script couldn't find UI elements

**Root Cause:**
- Tried to create demo BEFORE inputs page existed
- Guessing at UCC-generated UI structure
- Didn't verify actual HTML selectors

**Lesson:**
- Ensure feature works manually FIRST
- Inspect actual HTML before writing automation
- Create debug screenshots to see what automation sees
- Don't automate broken features

---

## Best Practices Established

### For UCC Development

1. **Always include BOTH pages:**
   - `configuration` - For accounts/settings
   - `inputs` - For data collection

2. **Modular Input Scheme Rules:**
   - ❌ Never define: name, interval, index, sourcetype
   - ✅ Only define: custom parameters
   - Still accessible in stream_events()

3. **Validation:**
   ```bash
   make lint    # Catches globalConfig errors early
   make build   # Full validation
   ```

4. **Testing Sequence:**
   - Build add-on
   - Install in Splunk
   - Configure via UI
   - Verify .conf files created
   - Test data collection
   - Check logs for errors

### For WSL Development

1. **Always check environment:**
   ```bash
   # Is Docker Desktop running?
   docker ps

   # Can reach containers?
   docker exec <container> curl <url>
   ```

2. **Network setup:**
   - Use external networks for multi-container setups
   - Document network names
   - Test connectivity between containers

3. **File paths:**
   - Provide both WSL and Windows paths
   - Use `cp` commands to move files to Windows
   - Document `\\wsl$\...` access

### For Demo/Automation

1. **Prerequisites check:**
   - Verify all services running
   - Test URLs manually first
   - Add health checks with retries

2. **Debugging aids:**
   - Screenshot at each step
   - Verbose logging
   - Clear error messages

3. **WSL considerations:**
   - Always use headless mode
   - Longer timeouts (Splunk startup)
   - Document both visible and headless options

---

## Technical Debt / Future Improvements

### Identified Issues

1. **Schema Version Warning:**
   ```
   WARNING: Schema version is not in the allowed versions, setting it to 0.0.0
   ```
   - Using 0.0.9 works but triggers warning
   - May need update when UCC releases new version

2. **Demo Video Not Yet Created:**
   - Framework exists (Playwright scripts)
   - Needs UI selector updates for actual UCC-generated pages
   - Consider manual recording as backup

3. **No Data Validation:**
   - Add-on ingests whatever API returns
   - No field mapping/transformation
   - Consider adding data normalization

4. **Error Handling:**
   - Basic try/catch exists
   - Could add retry logic for transient failures
   - Better error messages to users

### Recommended Next Steps

1. **Documentation:**
   - Create user guide with screenshots
   - Document eMASS API requirements
   - Add troubleshooting section

2. **Testing:**
   - Unit tests for Python code
   - Integration tests for data collection
   - UI tests for configuration pages

3. **Features:**
   - Support for other eMASS endpoints (not just POA&Ms)
   - Field extraction configuration
   - Data enrichment options

4. **Demo Video:**
   - Update Playwright selectors for UCC UI
   - Add narration/annotations
   - Create multiple versions (quick overview, detailed walkthrough)

---

## Key Metrics

**Time Spent:**
- Initial issue discovery: ~30 minutes
- Fixing modular input errors: ~2 hours
- Adding inputs page: ~1 hour
- Authentication fixes: ~30 minutes
- WSL setup and debugging: ~1 hour
- **Total: ~5 hours**

**Changes Made:**
- 15+ commits to branch
- 4 major configuration files updated
- 3 new scripts created (rebuild, cleanup, demo)
- 5 documentation files

**Files Modified:**
- `globalConfig.json` - Complete restructure
- `package/bin/emass_poam.py` - Fixed arguments, added user_uid
- `docker-compose.yml` - Network configuration
- `demo/*` - Complete demo framework

**Success Criteria:**
- ✅ Data ingesting into Splunk
- ✅ UI functional for account and input creation
- ✅ No modular input errors
- ✅ Works on WSL + Docker Desktop
- ✅ Documented and reproducible

---

## Conclusion

**What We Learned:**

1. **Foundation First:** Can't build a demo for broken functionality. Fix the core before adding features.

2. **UCC Has Rules:** Internal Splunk arguments must not be defined. Table goes at page level, not service level.

3. **Examples Are Gold:** Working globalConfig.json from Salesforce TA solved hours of guesswork.

4. **Environment Matters:** WSL + Docker Desktop has specific quirks that must be accommodated.

5. **Automation Saves Time:** `rebuild.sh` script paid for itself within 3 uses.

**What Worked:**
- Methodical debugging (fix one layer at a time)
- Using working examples as reference
- Creating reusable automation
- Comprehensive documentation

**What Didn't:**
- Trying to demo broken features
- Guessing at UCC structure
- Template variables for field population

**Final Status:**
The add-on now works end-to-end. Data flows from eMASS API → Splunk. The inputs UI allows users to configure collection without editing .conf files. The foundation is solid for future enhancements.

**Recommendation:**
Focus next on user documentation and deployment guide. The technical foundation is complete and working.

---

## Appendix: Quick Reference

### Build Sequence
```bash
make setup      # One-time: creates venv
make build      # Every change: builds add-on
make image      # Build Docker image
```

### Full Rebuild
```bash
./rebuild.sh    # Automated: pull, build, restart
```

### Check Data
```bash
# Search in Splunk
index=main sourcetype="emass:poam"

# Check logs
docker logs splunk-emass | grep -i emass

# Verify input configured
docker exec splunk-emass /opt/splunk/bin/splunk btool inputs list emass_poam
```

### Cleanup
```bash
cd demo
./cleanup_demo.sh          # Remove runtime files
./cleanup_complete.sh      # Remove everything
./cleanup_system_packages.sh  # Remove apt packages (optional)
```

### Demo Video (Future)
```bash
cd demo
./setup_demo.sh           # One-time setup
./run_demo_wsl.sh         # Create video (WSL mode)
./convert_to_mp4.sh       # Convert to MP4
```

---

**Document Version:** 1.0
**Last Updated:** November 8, 2025
**Author:** Claude (AI Assistant)
**Reviewed By:** User validation completed
