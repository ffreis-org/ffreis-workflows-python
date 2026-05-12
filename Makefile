.PHONY: help lint check fmt-check secrets-scan-staged lefthook-bootstrap lefthook-install hooks setup

WORKFLOWS_DIR := .github/workflows

## help: Show this help message
help:
	@echo "Available targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'

## lint: Validate workflow YAML + ruff on examples
lint:
	@echo "==> Validating workflow YAML files..."
	@if command -v yamllint > /dev/null 2>&1; then \
		yamllint -d '{extends: relaxed, rules: {line-length: {max: 160}}}' $(WORKFLOWS_DIR)/; \
		echo "All YAML files are valid."; \
	else \
		python3 -c "import yaml" >/dev/null 2>&1 || { \
			echo "ERROR: Neither yamllint nor PyYAML is available."; \
			echo "Install yamllint with 'pip install yamllint' or PyYAML with 'pip install pyyaml'."; \
			exit 1; \
		}; \
		for f in $(WORKFLOWS_DIR)/*.yml; do \
			python3 -c "import sys, yaml; yaml.safe_load(open('$$f'))" \
				&& echo "  OK: $$f" \
				|| { echo "  FAIL: $$f"; exit 1; }; \
		done; \
		echo "All YAML files are valid."; \
	fi
	@if command -v uv > /dev/null 2>&1; then \
		cd examples/hello && uv run ruff check .; \
	else \
		echo "uv not found; skipping ruff lint on examples"; \
	fi

## check: Run yamllint if available, otherwise fall back to lint
check:
	@if command -v yamllint > /dev/null 2>&1; then \
		echo "==> Running yamllint on $(WORKFLOWS_DIR)/..."; \
		yamllint -d '{extends: relaxed, rules: {line-length: {max: 160}}}' $(WORKFLOWS_DIR)/; \
	else \
		echo "yamllint not found — falling back to Python YAML validation."; \
		$(MAKE) lint; \
	fi

## fmt-check: Check Python example formatting with ruff
fmt-check:
	cd examples/hello && uv run ruff format --check .

## secrets-scan-staged: Scan staged files for secrets
secrets-scan-staged:
	@command -v gitleaks >/dev/null 2>&1 || { \
		echo "ERROR: gitleaks not found. Install it from https://github.com/gitleaks/gitleaks#installing"; \
		echo "Tip: run 'make setup' after installing to verify your dev environment."; \
		exit 1; \
	}
	gitleaks protect --staged --redact

## 
PLATFORM_STANDARDS_SHA := b6a9ef92199954e3da5b80814321cb92f649fb81
PLATFORM_STANDARDS_RAW := https://raw.githubusercontent.com/FelipeFuhr/ffreis-platform-standards

HOOK_SCRIPTS := \
	check_merge_markers.sh \
	check_large_files.sh \
	check_binary_files.sh \
	check_commit_msg.sh \
	check_required_tools.sh

hook-scripts: ## Download bootstrap + hook scripts from ffreis-platform-standards
	@mkdir -p scripts/hooks
	@curl -fsSL "$(PLATFORM_STANDARDS_RAW)/$(PLATFORM_STANDARDS_SHA)/lefthook/bootstrap_lefthook.sh" \
		-o scripts/bootstrap_lefthook.sh && chmod +x scripts/bootstrap_lefthook.sh
	@for script in $(HOOK_SCRIPTS); do \
		curl -fsSL "$(PLATFORM_STANDARDS_RAW)/$(PLATFORM_STANDARDS_SHA)/lefthook/scripts/$$script" \
			-o "scripts/hooks/$$script" && chmod +x "scripts/hooks/$$script"; \
	done
	@echo "Hook scripts downloaded."

lefthook-bootstrap: hook-scripts Download lefthook binary to .bin/
lefthook-bootstrap: hook-scripts
	LEFTHOOK_VERSION="1.7.10" BIN_DIR=".bin" bash ./scripts/bootstrap_lefthook.sh

## lefthook-install: Install git hooks via lefthook
lefthook-install:
	lefthook install

## hooks: Bootstrap and install all git hooks
hooks: lefthook-bootstrap lefthook-install

## setup: Install git hooks and verify required tools
setup: hooks
	@command -v gitleaks >/dev/null 2>&1 || { \
		echo ""; \
		echo "ACTION REQUIRED: gitleaks is not installed."; \
		echo "Install it from https://github.com/gitleaks/gitleaks#installing then re-run 'make setup'."; \
		echo ""; \
		exit 1; \
	}
	@echo "Dev environment ready."
