SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

PKG_DIR := package
OUT_DIR := output
VENV := .venv
PYTHON := python3.12
UCC_VERSION := 6.0.1
SPLUNK_VERSION := 9.2.1

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
	@rm -rf $(OUT_DIR)
	@source $(VENV)/bin/activate && ucc-gen build --source $(PKG_DIR) --ta-version 1.0.0
	@test -d $(OUT_DIR)/TA-securepro-eMASS || (echo '{"error":"build failed"}' && exit 1)
	@./fix_ui.sh
	@rm -f $(OUT_DIR)/TA-securepro-eMASS/appserver/static/openapi.json
	@find $(OUT_DIR) -name "output" -type d && (echo '{"error":"recursive output detected"}' && exit 1) || true
	@echo '{"status":"ok","size":'$$(du -sb $(OUT_DIR) | cut -f1)'}'

.PHONY: validate
validate:
	@echo '{"step":"validate","ts":"'$$(date -Iseconds)'"}'
	@test -f $(OUT_DIR)/TA-securepro-eMASS/default/app.conf || (echo '{"error":"app.conf missing"}' && exit 1)
	@test -f $(OUT_DIR)/TA-securepro-eMASS/default/restmap.conf || (echo '{"error":"restmap.conf missing"}' && exit 1)
	@test -d $(OUT_DIR)/TA-securepro-eMASS/bin || (echo '{"error":"bin directory missing"}' && exit 1)
	@test -d $(OUT_DIR)/TA-securepro-eMASS/lib/splunktaucclib || (echo '{"error":"splunktaucclib missing"}' && exit 1)
	@test -d $(OUT_DIR)/TA-securepro-eMASS/appserver/static/js/build || (echo '{"error":"UI files missing"}' && exit 1)
	@grep -q "version = 1.0.0" $(OUT_DIR)/TA-securepro-eMASS/default/app.conf || (echo '{"error":"version mismatch"}' && exit 1)
	@[ "$$(find $(OUT_DIR)/TA-securepro-eMASS/appserver/static/js/build -name '*.js' | wc -l)" -ge 20 ] || (echo '{"error":"insufficient UI files"}' && exit 1)
	@echo '{"status":"ok","files":'$$(find $(OUT_DIR) -type f | wc -l)'}'

.PHONY: image
image: build validate
	@echo '{"step":"image","ts":"'$$(date -Iseconds)'"}'
	@docker build -f Dockerfile-splunk-local -t ta-securepro-emass:latest \
		--build-arg SPLUNK_APP_PACKAGE=$(OUT_DIR)/TA-securepro-eMASS .
	@echo '{"status":"ok","image":"ta-securepro-emass:latest"}'

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
	@docker run --rm -v "$$(pwd)/$(OUT_DIR)":/output alpine sh -c "chmod -R 777 /output && rm -rf /output/*" 2>/dev/null || true
	@rm -rf $(OUT_DIR) 2>/dev/null || true
	@echo '{"status":"ok","message":"volumes cleaned"}'

.PHONY: clean
clean: clean-volumes
	@echo '{"step":"clean","ts":"'$$(date -Iseconds)'"}'
	@docker container prune -f
	@docker volume prune -f
	@rm -rf .venv 2>/dev/null || true
	@rm -rf output/ dist/ build/ __pycache__/ 2>/dev/null || true
	@echo '{"status":"ok"}'

.PHONY: help
help:
	@echo "Targets: preflight setup lint build validate image test-unit test-smoke clean clean-volumes"
