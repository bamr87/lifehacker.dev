# lifehacker.dev — developer entry points. Run `make` for the list.
.PHONY: help audit build serve test links todo scribe scribe-test

help: ## Show this help
	@grep -E '^[a-z][a-z-]*:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN{FS=":.*## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

audit: ## Full local QA gate (build + links + tests + TODO) — mirrors CI
	bash scripts/audit.sh

build: ## Build the site locally (Docker, faithful remote-theme overlay) → /tmp/lh-audit/_site
	PREVIEW_DIR=/tmp/lh-audit bash scripts/preview.sh build
	cd /tmp/lh-audit && docker compose run --rm --no-deps jekyll sh -c "(bundle check || bundle install) && bundle exec jekyll build --config _config.yml,_config_dev.yml"

serve: ## Live preview at http://localhost:4000
	bash scripts/preview.sh

test: ## Run the unit tests (session-scribe)
	bash scripts/test-session-scribe.sh

links: ## Check internal links in ./_site (build first, or pass DIR=)
	bash scripts/check-links.sh $(or $(DIR),_site)

todo: ## Scan for follow-up tags and (re)write TODO.md
	bash scripts/check-todos.sh --write

scribe: ## Write up any captured-but-unwritten sessions (draft PRs)
	bash scripts/session-scribe.sh drain
