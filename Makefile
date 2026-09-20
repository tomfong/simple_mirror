FLUTTER ?= flutter
DART ?= dart
WEB_PORT ?= 8081

.DEFAULT_GOAL := help

.PHONY: help get upgrade format format-check analyze test check run run-web build-android build-ios build-web clean doctor outdated

help: ## Show available commands.
	@printf "Simple Mirror commands:\n"
	@awk 'BEGIN { FS = ":.*##" } /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-18s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

get: ## Resolve Flutter dependencies.
	$(FLUTTER) pub get

upgrade: ## Upgrade Flutter dependencies within pubspec constraints.
	$(FLUTTER) pub upgrade

format: ## Format Dart source and tests.
	$(DART) format lib test

format-check: ## Verify Dart source and tests are formatted.
	$(DART) format --output=none --set-exit-if-changed lib test

analyze: ## Run Flutter static analysis.
	$(FLUTTER) analyze

test: ## Run widget and unit tests.
	$(FLUTTER) test

check: format-check analyze test ## Run formatting, analysis, and tests.

run: ## Run on the default Flutter device.
	$(FLUTTER) run

run-web: ## Serve the Web app locally; selects the next free port from WEB_PORT.
	@port="$(WEB_PORT)"; \
	while lsof -nP -iTCP:$$port -sTCP:LISTEN -t >/dev/null 2>&1; do \
		port=$$((port + 1)); \
	done; \
	if [ "$$port" != "$(WEB_PORT)" ]; then \
		printf "Port %s is in use; using http://localhost:%s instead.\n" "$(WEB_PORT)" "$$port"; \
	fi; \
	$(FLUTTER) run -d web-server --web-port $$port

build-android: ## Build a release Android APK.
	$(FLUTTER) build apk

build-ios: ## Build an unsigned iOS app for local verification.
	$(FLUTTER) build ios --no-codesign

build-web: ## Build the production Web PWA.
	$(FLUTTER) build web

clean: ## Remove generated Flutter build artifacts.
	$(FLUTTER) clean

doctor: ## Print Flutter environment diagnostics.
	$(FLUTTER) doctor -v

outdated: ## List dependencies with newer available versions.
	$(FLUTTER) pub outdated

deploy-web: ## Deploy the Web app to the production environment.
	$(FLUTTER) build web --release && npx wrangler pages deploy build/web --project-name simple-mirror