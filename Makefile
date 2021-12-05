# Output colors
GREEN=\033[1;32m
RESET=\033[0m
NEW_LINE=\n

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Web App

.PHONY: install
install: ## Install web app dependencies
	cd app/ && yarn install

.PHONY: test
test: ## Test the web app
	cd app/ && yarn test

.PHONY: build
build: ## Build the web app for production
	cd app/ && yarn build

.PHONY: dev-start
dev-start: ## Start the web app on http://localhost:3000/
	cd app/ && yarn start

##@ Assets

.PHONY: all-checks
all-checks: check-numbers nl check-names nl check-symbols nl check-files nl check-creators## Run all the checks

.PHONY: check-numbers
check-numbers: ## Check the number of assets (json and image files)
	@echo "${GREEN}Check the number of assets (json and image files)${RESET}"
	@echo -n "- Get count of asset files (metadata and image): "
	@find assets -type f  | wc -l

	@echo -n "- Get count of metadata files: "
	@find assets -type f -name '*.json' | wc -l

	@echo -n "- Get count of image files: "
	@find assets -type f -name '*.png' | wc -l

.PHONY: check-names
check-names: ## Check the name of the assets
	@echo "${GREEN}Check the name of the assets${RESET}"
	@echo "- Metadata files"
	@find assets -type f -name '*.json' |  xargs jq -r '.name' | sort | less

	@echo "- Image files"
	@find assets -type f -name '*.png' | sort | less

.PHONY: check-symbols
check-symbols: ## Check the symbols properties
	@echo "${GREEN}Check the symbols properties${RESET}"
	@find assets -type f -name '*.json' |  xargs jq -r '.symbol' | sort | uniq -c

.PHONY: check-files
check-files: ## Check the files properties
	@echo "${GREEN}Check the files properties${RESET}"
	@echo "- Uris"
	@find assets -type f -name '*.json' | xargs jq -r '.properties.files | .[] | [.uri] | .[0] | split(".") | .[1]' | sort | uniq -c
	@echo "- Types"
	@find assets -type f -name '*.json' | xargs jq -r '.properties.files' | jq -c '.[] | [.type]' | sort | uniq -c

.PHONY: check-creators
check-creators: ## Check the creators properties
	@echo "${GREEN}Check the creators properties${RESET}"
	@echo "- Addresses and shares"
	@find assets -type f -name '*.json' | xargs jq '.properties.creators' | jq -c '.[] | [.address,.share]' | sort | uniq -c
	@echo -n "- Sum of the shares: "
	@find assets -type f -name '*.json' | xargs jq '.properties.creators' | jq -c '.[] | [.address,.share]' | sort | uniq | jq '.[1]' | jq -s 'add'

.PHONY: nl
nl:
	@echo ""
