.DEFAULT_GOAL := help

EDCB_RELEASE := $(shell cat .edcb-release | tr -d '[:space:]')

EMWUI_COMMIT   := $(shell cat .emwui-commit | tr -d '[:space:]')
EMWUI_SHORT    := $(shell printf '%s' '$(EMWUI_COMMIT)' | cut -c1-7)
NEXT_TAG       := $(EDCB_RELEASE)-$(EMWUI_SHORT)

dryrun ?= true
tag    ?=

.PHONY: release
release: ## Release a new build. Usage: make release [dryrun=false]
	@echo "edcb release   : $(EDCB_RELEASE)"
	@printf '%s\n' '$(EMWUI_COMMIT)' | grep -Eq '^[0-9a-f]{40}$$' || { echo "Error: .emwui-commit must contain a full commit hash."; exit 1; }
	@echo "EMWUI commit   : $(EMWUI_COMMIT)"
	@echo "Next tag       : $(NEXT_TAG)"
	@set -e; if [ "$(dryrun)" = "false" ]; then \
		echo "Pushing to origin/master..."; \
		git push origin master --no-verify --force-with-lease; \
		echo "Creating tag $(NEXT_TAG)..."; \
		git tag -a $(NEXT_TAG) -m "Release $(NEXT_TAG)"; \
		git push origin $(NEXT_TAG); \
		echo "Creating GitHub release $(NEXT_TAG)..."; \
		gh release create $(NEXT_TAG) --title "Release $(NEXT_TAG)" --notes ""; \
		echo "Release $(NEXT_TAG) created."; \
	else \
		echo "[DRY RUN] Would push to origin/master"; \
		echo "[DRY RUN] Would create and push tag: $(NEXT_TAG)"; \
		echo "[DRY RUN] Would create GitHub release: $(NEXT_TAG)"; \
		echo ""; \
		echo "To execute, run:"; \
		echo "  make release dryrun=false"; \
	fi

.PHONY: re-release
re-release: ## Re-release an existing tag. Usage: make re-release [tag=<tag>] [dryrun=false]
	@set -e; TAG="$(tag)"; \
	if [ -z "$$TAG" ]; then \
		TAG=$$(git describe --tags --abbrev=0 2>/dev/null || true); \
	fi; \
	if [ -z "$$TAG" ]; then \
		echo "Error: No tag found. Specify with tag=<tag>."; \
		exit 1; \
	fi; \
	if [ "$$TAG" != "$(NEXT_TAG)" ]; then \
		echo "Error: Tag must match the configured versions: $(NEXT_TAG)"; \
		exit 1; \
	fi; \
	echo "Target tag: $$TAG"; \
	if [ "$(dryrun)" = "false" ]; then \
		echo "Deleting GitHub release..."; \
		gh release delete "$$TAG" --yes || true; \
		echo "Deleting local tag..."; \
		git tag -d "$$TAG"; \
		echo "Deleting remote tag..."; \
		git push origin ":refs/tags/$$TAG"; \
		echo "Recreating tag at HEAD..."; \
		git tag -a "$$TAG" -m "Release $$TAG"; \
		git push origin "$$TAG"; \
		echo "Creating GitHub release $$TAG..."; \
		gh release create "$$TAG" --title "Release $$TAG" --notes ""; \
		echo "Done!"; \
	else \
		echo "[DRY RUN] Would re-release tag: $$TAG"; \
		echo ""; \
		echo "To execute, run:"; \
		if [ -n "$(tag)" ]; then \
			echo "  make re-release tag=$$TAG dryrun=false"; \
		else \
			echo "  make re-release dryrun=false"; \
		fi; \
	fi

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
