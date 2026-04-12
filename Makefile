.DEFAULT_GOAL := help

EDCB_RELEASE := $(shell cat .edcb-release | tr -d '[:space:]')

# Get the latest tag matching <edcb-release>-<number> pattern
LATEST_TAG     := $(shell git tag --sort=-v:refname | grep -E "^$(EDCB_RELEASE)-[0-9]+$$" | head -n1)
LATEST_BUILD   := $(shell echo "$(LATEST_TAG)" | sed 's/.*-//')
NEXT_BUILD     := $(shell if [ -n "$(LATEST_BUILD)" ]; then expr $(LATEST_BUILD) + 1; else echo 1; fi)
NEXT_TAG       := $(EDCB_RELEASE)-$(NEXT_BUILD)

dryrun ?= true
tag    ?=

.PHONY: release
release: ## Release a new build. Usage: make release [dryrun=false]
	@echo "edcb release   : $(EDCB_RELEASE)"
	@echo "Current tag    : $(if $(LATEST_TAG),$(LATEST_TAG),(none))"
	@echo "Next tag       : $(NEXT_TAG)"
	@if [ "$(dryrun)" = "false" ]; then \
		echo "Pushing to origin/master..."; \
		git push origin master --no-verify --force-with-lease; \
		echo "Creating tag $(NEXT_TAG)..."; \
		git tag -a $(NEXT_TAG) -m "Release $(NEXT_TAG)"; \
		git push origin $(NEXT_TAG); \
		echo "Tag $(NEXT_TAG) created and pushed."; \
	else \
		echo "[DRY RUN] Would push to origin/master"; \
		echo "[DRY RUN] Would create and push tag: $(NEXT_TAG)"; \
		echo ""; \
		echo "To execute, run:"; \
		echo "  make release dryrun=false"; \
	fi

.PHONY: re-release
re-release: ## Re-release an existing tag. Usage: make re-release [tag=<tag>] [dryrun=false]
	@TAG="$(tag)"; \
	if [ -z "$$TAG" ]; then \
		TAG=$$(git describe --tags --abbrev=0 2>/dev/null); \
	fi; \
	if [ -z "$$TAG" ]; then \
		echo "Error: No tag found. Specify with tag=<tag>."; \
		exit 1; \
	fi; \
	echo "Target tag: $$TAG"; \
	if [ "$(dryrun)" = "false" ]; then \
		echo "Deleting local tag..."; \
		git tag -d "$$TAG"; \
		echo "Deleting remote tag..."; \
		git push origin ":refs/tags/$$TAG"; \
		echo "Recreating tag at HEAD..."; \
		git tag -a "$$TAG" -m "Release $$TAG"; \
		git push origin "$$TAG"; \
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
