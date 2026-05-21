# Lessons Learned: TA-suhlabs-eMASS Project

**Project:** Splunk UCC Technology Add-on Development
**Date:** 2025-11-01
**Status:** ✅ Resolved

---

## Executive Summary

This document captures critical lessons learned from building a Splunk UCC-based Technology Add-on, including the root cause analysis of build failures, antipatterns discovered, and best practices established.

**Key Discovery:** Virtual environment location was the root cause of 90% of build issues.

---

## Critical Issues & Root Cause Analysis

### Issue 1: Virtual Environment Location (ROOT CAUSE)

**Problem:**

- Build inconsistencies
- Dependencies not found
- UCC not generating files properly
- VSCode import errors

**Root Cause:**
Virtual environment created in `package/.venv/` instead of project root `.venv/`

**Why This Happened:**

- Misunderstanding of UCC documentation
- Assumption that venv should be near source files
- No explicit error message from UCC about wrong venv location

**Impact:**

- 🔴 Critical: Caused cascading failures in all build steps
- 🔴 Critical: Masked the real UCC 6.0.1 UI bug
- 🟡 Medium: Wasted 2+ hours debugging secondary symptoms

**Resolution:**

1. Deleted `package/.venv/`
2. Created `.venv/` at project root
3. Updated Makefile `VENV := .venv`
4. Reinstalled UCC 6.0.1 in correct location

**Lesson Learned:**

> **Always verify infrastructure assumptions first before debugging application logic.**

**Prevention:**

- Add preflight check: `test ! -d package/.venv`
- Document venv location explicitly in README
- Use absolute paths in documentation

---

### Issue 2: UCC 6.0.1 UI Bundle Bug

**Problem:**
Only `globalConfig.json` generated in `appserver/static/js/build/`, missing 22 JavaScript files needed for web UI

**Root Cause:**
UCC 6.0.1 packaging bug - UI files included in wheel package but not copied during `ucc-gen build`

**Why This Happened:**

- UCC v6.0.1 changelog claims to fix "include built UI files in the wheel package"
- Fix was incomplete - files are IN the package but build command doesn't copy them

**Impact:**

- 🔴 Critical: Configuration and Inputs pages won't render in Splunk Web
- 🟡 Medium: Silent failure (build succeeds but UI broken)
- 🟢 Low: Workaround available

**Resolution:**
Created `fix_ui.sh` script to manually copy UI files from UCC package to output after build

**Lesson Learned:**

> **Don't assume version increments fix all related issues. Verify the fix addresses your specific problem.**

**Prevention:**

- Test UI file generation in CI/CD pipeline
- Add validation check for minimum JS file count
- Monitor UCC release notes for permanent fix

---

### Issue 3: Invalid restmap.conf Keys

**Problem:**
VSCode validation errors: "invalid key in stanza"

- `handlertype = python`
- `handlerpersistentmode = true`

**Root Cause:**
Invalid Splunk configuration keys (not part of restmap.conf specification)

**Why This Happened:**

- Copied from outdated example or documentation
- No validation during UCC generation
- VSCode caught it but build didn't fail

**Impact:**

- 🟡 Medium: Confusing validation errors
- 🟡 Medium: Potential runtime issues with REST endpoints
- 🟢 Low: Easy to fix once identified

**Resolution:**
Removed invalid keys, kept only valid ones:

- `handlerfile`
- `handleractions`
- `match`
- `members`

**Lesson Learned:**

> **IDE warnings are valuable signals. Don't ignore them even if builds succeed.**

**Prevention:**

- Validate configuration files against official Splunk specs
- Use linters specific to Splunk configuration
- Create validation test in Makefile

---

### Issue 4: Docker Permission Denied on Output Directory

**Problem:**
Packaging scripts or manual file operations fail with "Permission denied" when accessing `output/TA-suhlabs-eMASS/local` or `metadata/local.meta`.

**Root Cause:**
The `make build` process runs `docker compose up`, which mounts the `output/` directory into the Splunk container. Splunk runs as root (or the splunk user) inside the container and creates runtime files (like `local/` configs) with `root` ownership. The host user (WSL) cannot modify or read them.

**Why This Happened:**

- Docker volumes inherit permissions from the container process.
- Splunk writes runtime files to `etc/apps/TA-suhlabs-eMASS/local` upon startup.

**Impact:**

- 🔴 Critical: Packaging scripts fail.
- 🟡 Medium: User cannot delete or modify output folder without `sudo`.

**Resolution:**

- Added ownership fix command to documentation/scripts: `sudo chown -R $USER:$USER output/`
- Updated packaging script to warn about this specific issue.

**Lesson Learned:**

> **Docker-generated artifacts often require explicit ownership fixes before host processing.**

**Prevention:**

- Add a `fix-perms` target to Makefile.
- Run Docker containers with the `--user` flag matching the host (though complex with Splunk).

---

## Antipatterns Discovered

### 1. ❌ Nested Virtual Environments

**Antipattern:**

```
project/
├── package/
│   └── .venv/          ❌ WRONG
```

**Correct Pattern:**

```
project/
├── .venv/              ✅ CORRECT
└── package/
```

**Why It's Wrong:**

- UCC expects venv at project root
- Creates confusion about dependency scope
- Breaks relative path assumptions

**Rule:**

> Virtual environments belong at the PROJECT ROOT, not in subdirectories.

---

### 2. ❌ Assuming Build Success = Deployment Ready

**Antipattern:**

```bash
ucc-gen build --source package
# Build succeeded! Ship it!
```

**Correct Pattern:**

```bash
ucc-gen build --source package
./fix_ui.sh
make validate  # Verify outputs
# Check UI file count
# Verify all components present
```

**Why It's Wrong:**

- Build can succeed but miss critical files (UI bundles)
- Silent failures harm user experience
- No validation = undetected issues

**Rule:**

> Always validate build outputs, not just build exit codes.

---

### 3. ❌ Hardcoded Paths in Build Scripts

**Antipattern:**

```makefile
VENV := package/.venv
build:
    cd package && ../package/.venv/bin/ucc-gen build
```

**Correct Pattern:**

```makefile
VENV := .venv
PKG_DIR := package
build:
    source $(VENV)/bin/activate && ucc-gen build --source $(PKG_DIR)
```

**Why It's Wrong:**

- Brittle when directory structure changes
- Hard to test in different environments
- Violates principle of least surprise

**Rule:**

> Use variables and relative paths that work from project root.

---

### 4. ❌ Ignoring Version Changelog Details

**Antipattern:**

```
v6.0.1 says "fixes UI files" → Upgrade → Assume fixed
```

**Correct Pattern:**

```
v6.0.1 says "fixes UI files"
→ Upgrade
→ Test UI generation
→ Verify 22 JS files present
→ Confirm fix worked
```

**Why It's Wrong:**

- Changelog may describe partial fixes
- Your specific use case might not be covered
- Silent regressions possible

**Rule:**

> Trust but verify. Always test that version upgrades solve YOUR problem.

---

### 5. ❌ No Validation Layer Between Build and Deploy

**Antipattern:**

```
Build → Deploy to Production
```

**Correct Pattern:**

```
Build → Validate → Test → Deploy to Production
```

**Why It's Wrong:**

- Missing files discovered in production
- No safety net for silent failures
- Difficult to debug production issues

**Rule:**

> Add a validation step that checks for required artifacts before deployment.

---

## Best Practices Established

### 1. ✅ Preflight Checks

**Implementation:**

```makefile
.PHONY: preflight
preflight:
    @test -d $(PKG_DIR) || exit 1
    @test ! -d package/.venv || (echo "Wrong venv location" && exit 1)
    @$(PYTHON) --version
```

**Benefit:**
Catches infrastructure issues before wasting time on build

---

### 2. ✅ Comprehensive Validation

**Implementation:**

```makefile
validate:
    @test -f output/app.conf
    @test -d output/lib/splunktaucclib
    @[ "$(JS_COUNT)" -ge 20 ]  # Validate UI files
```

**Benefit:**
Detects missing components immediately after build

---

### 3. ✅ Structured JSON Logging

**Implementation:**

```makefile
build:
    @echo '{"step":"build","ts":"'$(date -Iseconds)'"}'
    # ... build steps ...
    @echo '{"status":"ok","size":'$(du -sb output | cut -f1)'}'
```

**Benefit:**

- Parseable logs for CI/CD
- Easy to track progress
- Machine-readable status

---

### 4. ✅ Documentation as Code

**Files Created:**

- `CHANGES_SUMMARY.md` - Complete change history
- `BUG_REPORT.md` - Reproducible bug report
- `TEST_RESULTS.md` - Validation evidence
- `LESSONS_LEARNED.md` - This document

**Benefit:**

- Knowledge transfer
- Future debugging reference
- Onboarding new developers

---

### 5. ✅ Workaround Scripts with Clear Purpose

**Implementation:**

```bash
#!/bin/bash
# fix_ui.sh - Workaround for UCC 6.0.1 UI bug
# Bug: UI files not copied to output
# Permanent fix: Wait for UCC v6.0.2+

cp -r .venv/lib/.../appserver output/
```

**Benefit:**

- Clear intent documented
- Easy to remove when bug fixed
- Self-documenting code

---

## Machine Learning Model Building: Antipatterns

### ML Antipattern 1: ❌ Training on Entire Dataset Without Validation Split

**Antipattern:**

```python
# Load all data
X, y = load_data()

# Train on everything
model.fit(X, y)

# Check accuracy
print(f"Accuracy: {model.score(X, y)}")  # 99%! 🎉
```

**Why It's Wrong:**

- **Overfitting:** Model memorizes training data
- **No generalization:** High train accuracy, poor real-world performance
- **Data leakage:** Test metrics meaningless
- **False confidence:** Can't detect when model fails on new data

**Correct Pattern:**

```python
from sklearn.model_selection import train_test_split

X, y = load_data()

# Split data BEFORE any preprocessing
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# Train only on training set
model.fit(X_train, y_train)

# Evaluate on held-out test set
test_accuracy = model.score(X_test, y_test)
print(f"Test Accuracy: {test_accuracy}")
```

**Impact:**

- 🔴 Critical: Model useless in production
- 🔴 Critical: Wasted compute resources
- 🔴 Critical: False business decisions based on inflated metrics

**Rule:**

> **Always split data BEFORE training. Never evaluate on training data.**

---

### ML Antipattern 2: ❌ Leaking Information from Test Set

**Antipattern:**

```python
# Scale entire dataset first
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)  # ❌ Fit on ALL data

# Then split
X_train, X_test = train_test_split(X_scaled, test_size=0.2)

model.fit(X_train, y_train)
```

**Why It's Wrong:**

- **Data leakage:** Scaler "sees" test set during fit()
- **Optimistic metrics:** Test set influenced by training distribution
- **Won't work in production:** New data won't have same scaling
- **Subtle bug:** Metrics look good but model fails on real data

**Correct Pattern:**

```python
# Split FIRST
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Fit scaler ONLY on training data
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)

# Transform test data using training scaler
X_test_scaled = scaler.transform(X_test)  # Only transform, no fit

model.fit(X_train_scaled, y_train)
model.score(X_test_scaled, y_test)
```

**Impact:**

- 🔴 Critical: 5-20% drop in production accuracy
- 🟡 Medium: Expensive retraining required
- 🟡 Medium: Loss of user trust

**Rule:**

> **Fit preprocessing ONLY on training data. Transform test data using training parameters.**

---

### ML Antipattern 3: ❌ Not Setting Random Seeds

**Antipattern:**

```python
# No random seed
X_train, X_test = train_test_split(X, y, test_size=0.2)
model = RandomForestClassifier()
model.fit(X_train, y_train)

# Run 1: Accuracy = 87%
# Run 2: Accuracy = 82%
# Run 3: Accuracy = 91%
# Which one is real?? 🤔
```

**Why It's Wrong:**

- **Non-reproducible:** Can't recreate results
- **Can't debug:** Different results each run
- **No collaboration:** Team can't verify findings
- **Hyperparameter tuning useless:** Can't tell if improvement is real or random

**Correct Pattern:**

```python
import random
import numpy as np

# Set ALL random seeds
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# Use seed in all random operations
X_train, X_test = train_test_split(X, y, test_size=0.2, random_state=SEED)
model = RandomForestClassifier(random_state=SEED)
model.fit(X_train, y_train)

# Every run: Accuracy = 87%
# Reproducible! ✅
```

**Impact:**

- 🔴 Critical: Results not reproducible
- 🟡 Medium: Wastes time debugging phantom issues
- 🟡 Medium: Can't comply with audit requirements

**Rule:**

> **Always set random seeds for reproducibility. Document the seed value.**

---

### ML Antipattern 4: ❌ Using Accuracy for Imbalanced Datasets

**Antipattern:**

```python
# Fraud detection: 99% legitimate, 1% fraud
y = [0, 0, 0, ..., 1]  # 99% class 0, 1% class 1

# Dumb model: Always predict "not fraud"
predictions = [0] * len(y)

# Calculate accuracy
accuracy = (predictions == y).sum() / len(y)
print(f"Accuracy: {accuracy}")  # 99%! 🎉

# But model is USELESS - misses all fraud!
```

**Why It's Wrong:**

- **Misleading metric:** 99% accuracy but catches 0% fraud
- **Class imbalance ignored:** Minority class not learned
- **Business impact:** Expensive false negatives
- **Wrong optimization:** Model learns to ignore minority class

**Correct Pattern:**

```python
from sklearn.metrics import classification_report, confusion_matrix, f1_score, roc_auc_score

# Train model
model.fit(X_train, y_train)
y_pred = model.predict(X_test)
y_proba = model.predict_proba(X_test)[:, 1]

# Use appropriate metrics for imbalanced data
print(classification_report(y_test, y_pred))
print(confusion_matrix(y_test, y_pred))

# Focus on minority class
f1 = f1_score(y_test, y_pred, pos_label=1)
auc = roc_auc_score(y_test, y_proba)

print(f"F1 Score (fraud class): {f1}")
print(f"ROC AUC: {auc}")

# Set business-aware threshold
# "Catching 80% of fraud with 10% false positive rate is acceptable"
```

**Impact:**

- 🔴 Critical: Model useless for intended purpose
- 🔴 Critical: Business losses (missed fraud, failed diagnoses)
- 🟡 Medium: Wasted model development effort

**Rule:**

> **For imbalanced data, use precision, recall, F1-score, or ROC AUC instead of accuracy.**

---

### ML Antipattern 5: ❌ Feature Engineering After Train/Test Split

**Antipattern:**

```python
# Split first
X_train, X_test = train_test_split(data, test_size=0.2)

# Then engineer features on each separately
X_train['new_feature'] = complex_calculation(X_train)  # ❌
X_test['new_feature'] = complex_calculation(X_test)    # ❌

# Problem: Train and test might have different feature distributions!
```

**Why It's Wrong:**

- **Inconsistent features:** Different calculations on train vs test
- **Can't reproduce in production:** Feature engineering not in pipeline
- **Data leakage risk:** If calculation uses global statistics
- **Maintenance nightmare:** Feature logic in multiple places

**Correct Pattern:**

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer

# Define feature engineering as a function
def create_features(X):
    X = X.copy()
    X['new_feature'] = complex_calculation(X)
    return X

# Create pipeline
pipeline = Pipeline([
    ('feature_engineering', FunctionTransformer(create_features)),
    ('scaler', StandardScaler()),
    ('model', RandomForestClassifier())
])

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Pipeline applies same transformations to both
pipeline.fit(X_train, y_train)
pipeline.score(X_test, y_test)

# Easy to deploy: pipeline.predict(new_data)
```

**Impact:**

- 🔴 Critical: Production model fails due to feature mismatch
- 🟡 Medium: Difficult to debug feature inconsistencies
- 🟡 Medium: Expensive retraining required

**Rule:**

> **Encode feature engineering in a pipeline. Apply consistently to train, test, and production.**

---

### ML Antipattern 6: ❌ Not Validating Input Data Schema

**Antipattern:**

```python
# Load model
model = load_model('fraud_detector.pkl')

# Make prediction on new data
new_data = pd.read_csv('incoming_transactions.csv')
prediction = model.predict(new_data)  # 💥 Error: feature mismatch!

# Features changed:
# Training: ['amount', 'merchant', 'location']
# Production: ['amount', 'merchant_id', 'lat', 'lon']
```

**Why It's Wrong:**

- **Silent failures:** Model expects different features
- **Runtime errors:** Production crashes
- **Incorrect predictions:** Wrong features used
- **No validation:** Changes undetected until production

**Correct Pattern:**

```python
from pydantic import BaseModel, validator

# Define expected schema
class TransactionSchema(BaseModel):
    amount: float
    merchant: str
    location: str

    @validator('amount')
    def amount_positive(cls, v):
        if v < 0:
            raise ValueError('Amount must be positive')
        return v

# Validate before prediction
def predict(raw_data):
    # Validate schema
    try:
        validated = TransactionSchema(**raw_data)
    except ValidationError as e:
        logger.error(f"Schema validation failed: {e}")
        raise

    # Convert to DataFrame
    df = pd.DataFrame([validated.dict()])

    # Make prediction
    return model.predict(df)

# Catches issues before they reach model
```

**Impact:**

- 🔴 Critical: Production failures
- 🔴 Critical: Incorrect business decisions
- 🟡 Medium: Emergency hotfixes required

**Rule:**

> **Validate input data schema before model prediction. Fail fast on mismatches.**

---

### ML Antipattern 7: ❌ Overfitting to Validation Set

**Antipattern:**

```python
# Hyperparameter tuning
X_train, X_val = train_test_split(X, y, test_size=0.2)

best_score = 0
best_params = None

# Try many hyperparameters
for depth in range(1, 100):
    for n_estimators in range(10, 1000, 10):
        model = RandomForest(max_depth=depth, n_estimators=n_estimators)
        model.fit(X_train, y_train)

        score = model.score(X_val, y_val)
        if score > best_score:
            best_score = score
            best_params = (depth, n_estimators)

# best_score is OVERFITTED to validation set!
# Real performance will be worse
```

**Why It's Wrong:**

- **Validation set memorization:** Picked parameters that work for THIS validation set
- **Optimistic metrics:** Performance drops on truly new data
- **No test set:** Can't measure true generalization
- **Multiple testing problem:** Trying many parameters inflates metrics

**Correct Pattern:**

```python
from sklearn.model_selection import GridSearchCV

# Use cross-validation instead of single validation split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

param_grid = {
    'max_depth': range(1, 20),
    'n_estimators': [50, 100, 200, 500]
}

# Cross-validation on training set
grid_search = GridSearchCV(
    RandomForestClassifier(),
    param_grid,
    cv=5,  # 5-fold cross-validation
    scoring='f1',
    n_jobs=-1
)

grid_search.fit(X_train, y_train)

# Best params from CV
best_model = grid_search.best_estimator_

# Evaluate on HELD-OUT test set (never seen during tuning)
final_score = best_model.score(X_test, y_test)
print(f"True generalization score: {final_score}")
```

**Impact:**

- 🔴 Critical: 10-30% performance drop in production
- 🟡 Medium: Wasted hyperparameter tuning effort
- 🟡 Medium: Expensive retraining

**Rule:**

> **Use cross-validation for hyperparameter tuning. Always evaluate on a held-out test set.**

---

## Summary: Key Takeaways

### UCC Development

1. ✅ Virtual environments belong at project root
2. ✅ Validate build outputs, not just exit codes
3. ✅ Trust but verify version upgrade fixes
4. ✅ IDE warnings are valuable signals
5. ✅ Document workarounds with clear intent

### Machine Learning

1. ✅ Always split data before any preprocessing
2. ✅ Fit preprocessing only on training data
3. ✅ Set random seeds for reproducibility
4. ✅ Use appropriate metrics for imbalanced data
5. ✅ Encode feature engineering in pipelines
6. ✅ Validate input schema before prediction
7. ✅ Use cross-validation for hyperparameter tuning

### Universal Principles

- **Verify assumptions before debugging logic**
- **Validate outputs at every stage**
- **Document workarounds and their purpose**
- **Fail fast with clear error messages**
- **Make processes reproducible**

---

## Issue 8: UCC Outputs Page Not Supported (CRITICAL DISCOVERY)

**Problem:**

- Attempted to add an "outputs" page to `globalConfig.json`
- Build failed with error: `Additional properties are not allowed ('outputs' was unexpected)`
- Previous implementation was lost when another LLM deleted it

**Root Cause:**
UCC framework **does not support** a top-level "outputs" page in `globalConfig.json`

**Supported Page Types:**

```json
{
  "pages": {
    "configuration": {}, // ✅ Supported
    "inputs": {}, // ✅ Supported
    "dashboard": {}, // ✅ Supported (UCC v5.42.0+)
    "outputs": {} // ❌ NOT SUPPORTED
  }
}
```

**Impact:**

- 🔴 Critical: Lost output configuration when file was "cleaned up"
- 🟡 Medium: Confusion about how to implement POST/PUT operations
- 🟢 Low: Easy to fix once understood

**Resolution:**
Two approaches for output functionality:

### Approach 1: Configuration Tab (IMPLEMENTED) ✅

Add output settings as a **tab within the configuration page**:

```json
{
  "pages": {
    "configuration": {
      "tabs": [
        {
          "name": "account",
          "title": "eMASS Account"
        },
        {
          "name": "output", // ✅ Output tab
          "title": "Output Settings",
          "entity": [
            {
              "field": "name",
              "label": "Output Name",
              "type": "text",
              "required": true
            },
            {
              "field": "http_method",
              "label": "HTTP Method",
              "type": "singleSelect",
              "options": {
                "autoCompleteFields": [
                  { "label": "POST - Create new POAM", "value": "POST" },
                  { "label": "PUT - Update existing POAM", "value": "PUT" }
                ]
              }
            },
            {
              "field": "endpoint",
              "label": "API Endpoint",
              "type": "text",
              "defaultValue": "/api/systems/{system_id}/poams"
            }
          ]
        },
        {
          "type": "loggingTab",
          "label": "Log Level"
        }
      ]
    }
  }
}
```

**Location in UI:** Configuration → Output Settings tab

### Approach 2: Alert Actions (Alternative)

For event-driven outputs, use alert actions:

```json
{
  "alerts": [
    {
      "name": "emass_poam_update",
      "label": "Update eMASS POAM",
      "description": "Send POAM updates to eMASS via POST/PUT"
    }
  ]
}
```

**Lesson Learned:**

> **UCC configuration tabs vs. pages: Configuration tabs can hold any settings, including "output" configurations. Don't assume you need a separate page for every feature.**

**Prevention:**

- ✅ Document UCC schema limitations in this file
- ✅ Keep `CHECKPOINTING_IMPLEMENTATION.md` as backup
- ✅ Use version control to track `globalConfig.json` changes
- ✅ Test build after any `globalConfig.json` modifications

---

## Issue 9: Checkpointing Implementation Best Practices

**Problem:**

- Checkpointing was imported but not implemented
- Input collected ALL POAMs on every run
- No duplicate prevention
- Inefficient for large datasets

**Root Cause:**
Import statement existed but actual checkpointing logic was never added

**Impact:**

- 🟡 Medium: Duplicate events in Splunk
- 🟡 Medium: Unnecessary API load
- 🟢 Low: Works but inefficient

**Resolution:**
Implemented comprehensive checkpointing for both inputs and outputs

### Input Checkpointing Pattern:

```python
from solnlib.modular_input import checkpointer

# Initialize checkpointer
ckpt = checkpointer.KVStoreCheckpointer(
    "ta_suhlabs_emass_emass_poam",
    session_key,
    "TA-suhlabs-eMASS"
)

# Get last collection time
checkpoint_key = f"{input_name}_last_collection"
last_collection_time = ckpt.get(checkpoint_key)

# Collect only new/updated data
poams = self._collect_poams(api_url, api_key, user_uid, last_collection_time)

# Update checkpoint after success
current_time = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
ckpt.update(checkpoint_key, current_time)
```

### Filtering Strategy:

1. **API Parameter**: Send `lastModifiedDate` to API
2. **Client-side Filter**: Check multiple date fields:
   - `lastModifiedDate`
   - `last_modified_date`
   - `updatedDate`
   - `updated_date`
   - `modifiedDate`
3. **Safe Default**: Include POAMs without date fields

### Output Modular Script:

Created `package/bin/emass_poam_output.py` for POST/PUT operations:

```python
def _send_poam_update(
    self,
    api_url: str,
    api_key: str,
    poam_data: Dict[str, Any],
    http_method: str = "POST",
    user_uid: Optional[str] = None,
    poam_id: Optional[str] = None
) -> bool:
    """Send POAM update to eMASS API"""

    # Construct URL based on method
    if http_method == "PUT" and poam_id:
        url = f"{api_url}/{poam_id}"
    else:
        url = api_url

    # Send request
    if http_method == "POST":
        response = requests.post(url, headers=headers, json=poam_data, timeout=30)
    elif http_method == "PUT":
        response = requests.put(url, headers=headers, json=poam_data, timeout=30)

    return response.status_code in [200, 201, 204]
```

**Lesson Learned:**

> **Checkpointing is essential for production modular inputs. Always implement it from the start, not as an afterthought.**

**Best Practices:**

- ✅ Use KVStoreCheckpointer for persistence
- ✅ Store ISO 8601 timestamps
- ✅ Filter by multiple date field names (APIs vary)
- ✅ Update checkpoint only after successful write
- ✅ Handle first-time runs gracefully (no checkpoint)
- ✅ Log checkpoint updates for debugging

**Files Involved:**

- `package/bin/emass_poam.py` - Input with checkpointing
- `package/bin/emass_poam_output.py` - Output modular script
- `CHECKPOINTING_IMPLEMENTATION.md` - Full documentation

---

## Issue 10: Splunkbase Packaging Commands

**Problem:**

- Unclear how to package add-on for Splunkbase submission
- Multiple UCC commands available but documentation sparse

**Resolution:**

### Complete Build & Package Workflow:

```bash
# 1. Clean previous builds
rm -rf output

# 2. Build the add-on
make build

# OR manually:
source .venv/bin/activate
ucc-gen build --source package --ta-version 1.0.0

# 3. Package for Splunkbase
source .venv/bin/activate
ucc-gen package --path output/TA-suhlabs-eMASS
```

**Output:**

- Creates: `TA-suhlabs-eMASS-<version>.tar.gz`
- Location: Project root directory
- Ready for: Splunkbase upload

**Lesson Learned:**

> **The `ucc-gen package` command requires the built output directory path, not the source package directory.**

**Splunkbase Checklist:**

- ✅ Version in `globalConfig.json` is correct
- ✅ `app.manifest` metadata is complete
- ✅ README and documentation updated
- ✅ Screenshots prepared
- ✅ Test `.tar.gz` in clean Splunk instance
- ✅ No Mako templates (security check)
- ✅ No compiled binaries (aarch64 compatibility)

---

## Issue 11: Security and Compatibility Checks

**Problem:**

- Splunkbase has strict security and compatibility requirements
- Two specific checks mentioned:
  1. `check_for_existence_of_python_code_block_in_mako_template`
  2. `check_idx_binary_compatibility`

**Investigation Results:**

### Check 1: Mako Templates ✅ PASS

```bash
find . -name "*.mako" -o -name "*.tmpl"
# Result: No files found (only in venv dependencies)
```

**Finding:** No Mako templates in project code

- Mako only exists in virtual environment (pip packages)
- No security vulnerability from deprecated templates

### Check 2: Binary Compatibility ✅ PASS

```bash
find package/bin -type f ! -name "*.py" ! -name "*.sh" ! -name "*.txt"
# Result: No compiled binaries
```

**Finding:** Pure Python implementation

- No compiled binaries distributed
- Works on all architectures (x86_64, aarch64, etc.)
- No compatibility issues with ARM-based indexers

**Lesson Learned:**

> **Pure Python add-ons are ideal for Splunkbase - they're secure, portable, and have no architecture dependencies.**

**Best Practices:**

- ✅ Avoid Mako templates (use Jinja2 if templating needed)
- ✅ Avoid compiled binaries (use pure Python)
- ✅ Test on multiple architectures if binaries required
- ✅ Document any platform-specific requirements

---

## Summary of New Lessons (2025-11-21)

### Critical Discoveries:

1. **UCC does NOT support top-level "outputs" page** - use configuration tabs instead
2. **Checkpointing must be actively implemented** - import alone does nothing
3. **Configuration tabs are flexible** - can hold any settings, not just accounts
4. **Pure Python is best** - avoids security and compatibility issues

### Implementation Patterns:

#### Pattern 1: Configuration Tab for Outputs

```
Configuration Page
├── Account Tab
├── Output Settings Tab ← Add here, not as separate page
└── Logging Tab
```

#### Pattern 2: Checkpointing

```python
# Initialize → Get → Filter → Process → Update
ckpt = KVStoreCheckpointer(...)
last_time = ckpt.get(key)
data = collect_filtered(last_time)
process(data)
ckpt.update(key, current_time)
```

#### Pattern 3: Modular Output

```python
# Separate script: package/bin/{name}_output.py
# Configured via: Configuration → Output Settings tab
# Triggered by: Splunk scheduler or events
```

### Files to Preserve:

- ✅ `globalConfig.json` - Contains output tab configuration
- ✅ `package/bin/emass_poam.py` - Input with checkpointing
- ✅ `package/bin/emass_poam_output.py` - Output script
- ✅ `CHECKPOINTING_IMPLEMENTATION.md` - Implementation docs
- ✅ `LESSONS_LEARNED.md` - This file

---

**Document Version:** 2.0
**Last Updated:** 2025-11-21
**Status:** Complete

---

---

## Session: 2026-04-27 — AppInspect Failures & Build Hardening

**Date:** 2026-04-27
**Status:** ✅ Resolved

> **Addendum:** UCC 6.0.x generated `[script:./bin/emass_poam.py]` stanzas in `inputs.conf`. UCC 6.1.0 changed to bare service-name stanzas `[emass_poam]`. The `fix_ui.sh` patcher's `^\[script:` pattern silently missed the stanza — no error, just no injection. Pattern updated to `^\[` (all stanzas in inputs.conf are modular inputs). **Lesson: verify patcher output against the actual generated file after every UCC version bump.**

---

### Issue 5: AppInspect `check_admin_external_restmap_conf_python_required` & `check_modular_inputs_python_required`

**Problem:**
Two AppInspect checks failed on the 1.0.0 release:
- `check_admin_external_restmap_conf_python_required` — `[admin_external:*]` stanzas in `restmap.conf` missing `python.required`
- `check_modular_inputs_python_required` — `[script:*]` stanzas in `inputs.conf` missing `python.required`

**Root Cause:**
UCC-gen 6.0.1 does not emit `python.required = python3` in generated conf files. This field became mandatory for Splunk Cloud Vetting in April 2026.

**Resolution:**
1. Bumped `splunk-add-on-ucc-framework` to `6.1.0` in **`requirements.txt`** (native support added in 6.1.0)
2. Added belt-and-suspenders Python patcher in `fix_ui.sh` to inject `python.required = python3` into any `[admin_external:*]` and `[script:*]` stanzas that lack it
3. Added `validate` checks to assert `python.required` is present in both files after every build

**Lesson Learned:**
> **`requirements.txt` is the authoritative version pin for pip — `UCC_VERSION` in the Makefile is purely cosmetic documentation. Always update `requirements.txt` when bumping a tool version.**

**Prevention:**
- Keep `UCC_VERSION` in Makefile in sync with `requirements.txt` (they are now both `6.1.0`)
- `make validate` now explicitly checks for `python.required` in both conf files

---

### Issue 6: Docker Root-Owned `output/` Blocks Rebuild (Lesson 4 Revisited)

**Problem:**
`make build` fails with hundreds of `Permission denied` errors when `rm -rf output/` runs. This is a recurrence of Issue 4 (Docker container writes files as root).

**Why Previous Fix Failed:**
- `chmod -R u+w output/ || true` silently no-ops: you cannot `chmod` files owned by root when running as a non-root user (kernel returns EPERM, not just a permission denied on the file)
- The `|| true` swallowed the chmod failure, so `rm` still blocked

**Resolution:**
Replaced `chmod + rm` pattern with `sudo rm -rf $(OUT_DIR)` in both `build` and `clean-volumes` targets. This is the same outcome as the Docker Alpine workaround but works without Docker available.

**Lesson Learned:**
> **You cannot `chmod` files you don't own. When Docker generates root-owned artifacts, `sudo rm -rf` is the only host-side fix that works without Docker.**

**Quick Fix (one-time):**
```bash
sudo rm -rf output/
make build
```

**Prevention:**
- `build` target now runs `sudo rm -rf $(OUT_DIR)` as the first step
- `clean-volumes` also uses `sudo rm -rf` — no longer relies on Docker Alpine workaround

---

### Issue 7: Hardcoded Version in `validate` Diverges from `build`

**Problem:**
`make validate` fails with `{"error":"version mismatch"}` because the validate check hardcoded `version = 1.0.0` while the build command used `--ta-version 1.0.1`.

**Root Cause:**
Version defined in two places — `--ta-version` arg in `build` and grep string in `validate` — with no shared variable enforcing consistency.

**Resolution:**
Introduced `TA_VERSION := 1.0.1` as a single Makefile variable used in both:
- `build`: `ucc-gen build --source $(PKG_DIR) --ta-version $(TA_VERSION)`
- `validate`: `grep -q "version = $(TA_VERSION)" ...`

**Lesson Learned:**
> **Any value that appears in more than one place in a Makefile must be a variable. Hardcoded strings always drift.**

**Prevention:**
- To release a new version, change only `TA_VERSION := X.Y.Z` — build and validate stay in sync automatically
- `validate` output now includes version: `{"status":"ok","version":"1.0.1",...}`

---

### Issue 8: False-Positive Recursive Output Guard

**Problem:**
`make build` printed `{"error":"recursive output detected"}` on every run after upgrading to UCC 6.1.0, even though there was no real recursion.

**Root Cause:**
The guard used `find $(OUT_DIR) -name "output" -type d` which matched directories named `output` inside installed lib packages (grpc/protobuf vendored code), not an actual recursive build loop.

**Resolution:**
Changed to `test ! -d $(OUT_DIR)/output` — only flags the specific case of `output/output/` existing (true recursion).

**Lesson Learned:**
> **`find -name X` in a deep tree will match unintended directories. Use path-specific checks (`test -d path/to/exact/dir`) for guards that need precision.**

---

### Issue 9: `proxyTab` Missing from UI — True Root Cause: `schemaVersion` Out of UCC's Allowed Range

**Problem:**
The **Proxy Settings** tab was completely missing from the Splunk Configuration page after every `make build`, despite the tab being correctly defined in `globalConfig.json` and the Python UCC pipeline simulation (debug script) showing it expanded with all 7 entities.

> [!NOTE]
> **Earlier diagnoses were incorrect.** Two false root causes were documented during investigation:
> - ~~`fix_ui.sh` wildcard `cp -r` overwrites `globalConfig.json` from UCC static assets~~ — **Disproved:** The UCC library's `package/appserver/static/js/build/` contains only `.js` files, no `globalConfig.json`.
> - ~~UCC migration pass strips proxyTab from in-memory config~~ — **Disproved:** Debug script confirmed the full pipeline correctly serializes proxy through all migration passes.

**True Root Cause:**
`globalConfig.json` had `"schemaVersion": "0.0.10"` in its `meta` block. UCC's `handle_global_config_update()` in `global_config_update.py` maintains an explicit allowlist of recognized schema versions:

```python
allowed_versions_of_schema_version = {
    "0.0.0", "0.0.1", "0.0.2", "0.0.3", "0.0.4",
    "0.0.5", "0.0.6", "0.0.7", "0.0.8", "0.0.9",
}
```

`"0.0.10"` is **not in this set**. So on every build, UCC silently resets the version to `"0.0.0"` and re-runs **all** migration passes. The 0.0.10 migration (`_remove_oauth_field_from_entites`) then writes `"schemaVersion": "0.0.10"` back to the source file — meaning every subsequent build hits the same trap, creating an infinite cycle where all migrations re-run every time and the proxyTab is never correctly included in the output.

**Resolution:**
Set `"schemaVersion": "0.0.9"` in `globalConfig.json`'s `meta` block:
```json
"meta": {
    "schemaVersion": "0.0.9"
}
```
This puts the version within the recognized range. UCC runs only the 0.0.10 migration once (which only removes deprecated `oauth_field` attributes — harmless for this TA) and leaves the proxyTab intact.

**Verification Command:**
After every `make build`, verify all expected tabs are in the compiled output:
```bash
jq '.pages.configuration.tabs[].name // .pages.configuration.tabs[].type' \
  output/TA-suhlabs-eMASS/appserver/static/js/build/globalConfig.json
```
Expected output:
```
"account"
"output"
"proxy"
"logging"
```

**Lesson Learned:**
> **UCC's `handle_global_config_update()` has a hardcoded allowlist of recognized `schemaVersion` values that does NOT include `"0.0.10"`. If your `schemaVersion` is outside the allowlist, UCC silently resets to `"0.0.0"` and re-runs ALL migrations on every build with no warning. Always ensure `schemaVersion` is within the recognized range. Check the allowlist in `global_config_update.py` whenever upgrading UCC.**

---

**Document Version:** 3.3
**Last Updated:** 2026-05-20
**Status:** Complete


