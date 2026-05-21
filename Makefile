SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

PKG_DIR := package
OUT_DIR := output
VENV := .venv
PYTHON := python3.12
UCC_VERSION := 6.1.0
TA_VERSION := 1.0.4
SPLUNK_VERSION := latest

.PHONY: bump
bump:
	@if [ -z "$(VERSION)" ]; then \
		echo '{"error":"Usage: make bump VERSION=x.y.z"}'; exit 1; \
	fi
	@echo '{"step":"bump","version":"$(VERSION)","ts":"'$$(date -Iseconds)'"}'
	@# Update TA_VERSION in this Makefile
	@sed -i 's/^TA_VERSION := .*/TA_VERSION := $(VERSION)/' Makefile
	@# Sync into package/app.manifest
	@jq --arg v "$(VERSION)" '.info.id.version = $$v' package/app.manifest > /tmp/_manifest.json \
		&& mv /tmp/_manifest.json package/app.manifest
	@# Sync into globalConfig.json meta.version
	@jq --arg v "$(VERSION)" '.meta.version = $$v' globalConfig.json > /tmp/_gc.json \
		&& mv /tmp/_gc.json globalConfig.json
	@echo '{"status":"ok","version":"$(VERSION)","updated":["Makefile","package/app.manifest","globalConfig.json"]}'

.PHONY: zip
zip:
	@./zip_ta.sh

.PHONY: preflight
preflight:
	@echo '{"step":"preflight","ts":"'$$(date -Iseconds)'"}'
	@$(PYTHON) --version | jq -Rs '{python:.}'
	@uname -a | jq -Rs '{os:.}'
	@test -d $(PKG_DIR) || (echo '{"error":"package dir missing"}' && exit 1)
	@echo '{"status":"ok"}'

.PHONY: setup
setup:
	@echo '{"step":"setup","ts":"'$$(date -Iseconds)'"}'
	@$(PYTHON) -m venv .venv
	@$(VENV)/bin/pip install --upgrade pip setuptools wheel
	@$(VENV)/bin/pip install -r requirements.txt
	@$(VENV)/bin/pip freeze | jq -Rs '{deps:.}'

.PHONY: lint
lint:
	@echo '{"step":"lint","ts":"'$$(date -Iseconds)'"}'
	@test -f globalConfig.json
	@jq empty globalConfig.json
	@echo '{"status":"ok"}'

.PHONY: build
build: lint
	@echo '{"step":"build","ts":"'$$(date -Iseconds)'"}'
	@if [ -d $(OUT_DIR) ] && [ "$$(stat -c %U $(OUT_DIR) 2>/dev/null)" = "root" ]; then sudo chown -R $$(id -u):$$(id -g) $(OUT_DIR) 2>/dev/null || true; fi
	@rm -rf $(OUT_DIR)
	@source $(VENV)/bin/activate && ucc-gen build --source $(PKG_DIR) --ta-version $(TA_VERSION)
	@test -d $(OUT_DIR)/TA-suhlabs-eMASS || (echo '{"error":"build failed"}' && exit 1)
	@./fix_ui.sh
	@rm -f $(OUT_DIR)/TA-suhlabs-eMASS/appserver/static/openapi.json
	@find $(OUT_DIR)/TA-suhlabs-eMASS/lib -name "*.so" -type f -delete
	@test ! -d $(OUT_DIR)/output || (echo '{"error":"recursive output detected"}' && exit 1)
	@echo '{"status":"ok","size":'$$(du -sb $(OUT_DIR) | cut -f1)'}'

.PHONY: validate
validate:
	@echo '{"step":"validate","ts":"'$$(date -Iseconds)'"}'
	@test -f $(OUT_DIR)/TA-suhlabs-eMASS/default/app.conf || (echo '{"error":"app.conf missing"}' && exit 1)
	@test -f $(OUT_DIR)/TA-suhlabs-eMASS/default/restmap.conf || (echo '{"error":"restmap.conf missing"}' && exit 1)
	@test -d $(OUT_DIR)/TA-suhlabs-eMASS/bin || (echo '{"error":"bin directory missing"}' && exit 1)
	@test -d $(OUT_DIR)/TA-suhlabs-eMASS/lib/splunktaucclib || (echo '{"error":"splunktaucclib missing"}' && exit 1)
	@test -d $(OUT_DIR)/TA-suhlabs-eMASS/appserver/static/js/build || (echo '{"error":"UI files missing"}' && exit 1)
	@grep -q "version = $(TA_VERSION)" $(OUT_DIR)/TA-suhlabs-eMASS/default/app.conf || (echo '{"error":"version mismatch — expected $(TA_VERSION)"}' && exit 1)
	@[ "$$(find $(OUT_DIR)/TA-suhlabs-eMASS/appserver/static/js/build -name '*.js' | wc -l)" -ge 20 ] || (echo '{"error":"insufficient UI files"}' && exit 1)
	@grep -q 'python.required' $(OUT_DIR)/TA-suhlabs-eMASS/default/restmap.conf || (echo '{"error":"python.required missing from restmap.conf"}' && exit 1)
	@grep -q 'python.required' $(OUT_DIR)/TA-suhlabs-eMASS/default/inputs.conf || (echo '{"error":"python.required missing from inputs.conf"}' && exit 1)
	@echo '{"status":"ok","version":"$(TA_VERSION)","files":'$$(find $(OUT_DIR) -type f | wc -l)'}'

.PHONY: image
image: build validate
	@echo '{"step":"image","ts":"'$$(date -Iseconds)'"}'
	@docker build --pull -f Dockerfile-splunk-local -t ta-suhlabs-emass:latest \
		--build-arg SPLUNK_VERSION=$(SPLUNK_VERSION) \
		--build-arg SPLUNK_APP_PACKAGE=$(OUT_DIR)/TA-suhlabs-eMASS .
	@echo '{"status":"ok","image":"ta-suhlabs-emass:latest"}'

.PHONY: test-unit
test-unit:
	@echo '{"step":"test-unit","ts":"'$$(date -Iseconds)'"}'
	@echo '{"status":"skip","reason":"no tests yet"}'

.PHONY: test-smoke
test-smoke: image
	@echo '{"step":"test-smoke","ts":"'$$(date -Iseconds)'"}'
	@docker-compose up -d
	@sleep 30
	@curl -sSf http://localhost:8000 >/dev/null
	@docker-compose down
	@echo '{"status":"ok"}'

.PHONY: clean-volumes
clean-volumes:
	@echo '{"step":"clean-volumes","ts":"'$$(date -Iseconds)'"}'
	@docker-compose down -v 2>/dev/null || true
	@if [ -d $(OUT_DIR) ] && [ "$$(stat -c %U $(OUT_DIR) 2>/dev/null)" = "root" ]; then sudo chown -R $$(id -u):$$(id -g) $(OUT_DIR) 2>/dev/null || true; fi
	@rm -rf $(OUT_DIR) 2>/dev/null || true
	@echo '{"status":"ok","message":"volumes cleaned"}'

.PHONY: clean
clean: clean-volumes
	@echo '{"step":"clean","ts":"'$$(date -Iseconds)'"}'
	@docker container prune -f 2>/dev/null || true
	@docker volume prune -f 2>/dev/null || true
	@rm -rf .venv 2>/dev/null || true
	@rm -rf output/ dist/ build/ __pycache__/ 2>/dev/null || true
	@echo '{"status":"ok"}'

.PHONY: help
help:
	@echo "Targets: preflight setup lint build validate image test-unit test-smoke clean clean-volumes"
