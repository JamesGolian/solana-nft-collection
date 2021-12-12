# Configuration
WEB_APP=$(shell pwd)/app
ASSETS=$(shell pwd)/assets
METAPLEX=$(shell pwd)/bin/metaplex
CONFIG=$(shell pwd)/config
SOL_DEVNET=$(CONFIG)/devnet.json

# Output colors
GREEN=\033[1;32m
RESET=\033[0m
NEW_LINE=\n


##@ General
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: break-line
break-line:
	@echo ""


##@ Web Application
.PHONY: wa-install
wa-install: ## Install web app dependencies.
	cd $(WEB_APP) && npm install && npx browserslist@latest --update-db

.PHONY: wa-env
wa-env: ## Show the environment variables.
	@echo "REACT_APP_CANDY_MACHINE_CONFIG: ${REACT_APP_CANDY_MACHINE_CONFIG}"
	@echo "REACT_APP_CANDY_MACHINE_ID: ${REACT_APP_CANDY_MACHINE_ID}"
	@echo "REACT_APP_TREASURY_ADDRESS: ${REACT_APP_TREASURY_ADDRESS}"
	@echo "REACT_APP_SOLANA_NETWORK: ${REACT_APP_SOLANA_NETWORK}"
	@echo "REACT_APP_SOLANA_RPC_HOST: ${REACT_APP_SOLANA_RPC_HOST}"

.PHONY: wa-test
wa-test: wa-env ## Test the web app.
	cd $(WEB_APP) && npm run test

.PHONY: wa-build
wa-build: wa-env ## Build the web app for production.
	cd $(WEB_APP) && npm run build

.PHONY: wa-start
wa-start: wa-env ## Start the web app on http://localhost:3000/.
	cd $(WEB_APP) && npm run start


##@ Assets Generation
.PHONY: check-all
check-all: check-numbers break-line check-names break-line check-symbols break-line check-files break-line check-creators ## Run all the checks.

.PHONY: check-numbers
check-numbers: ## Check the number of assets (json and image files).
	@echo "${GREEN}Check the number of assets (json and image files)${RESET}"
	@echo -n "- Get count of asset files (metadata and image): "
	@find $(ASSETS) -type f  | wc -l

	@echo -n "- Get count of metadata files: "
	@find $(ASSETS) -type f -name '*.json' | wc -l

	@echo -n "- Get count of image files: "
	@find $(ASSETS) -type f -name '*.png' | wc -l

.PHONY: check-names
check-names: ## Check the name of the assets.
	@echo "${GREEN}Check the name of the assets${RESET}"
	@echo "- Metadata files"
	@find $(ASSETS) -type f -name '*.json' |  xargs jq -r '.name' | sort | less

	@echo "- Image files"
	@find $(ASSETS) -type f -name '*.png' | sort | less

.PHONY: check-symbols
check-symbols: ## Check the symbols properties.
	@echo "${GREEN}Check the symbols properties${RESET}"
	@find $(ASSETS) -type f -name '*.json' |  xargs jq -r '.symbol' | sort | uniq -c

.PHONY: check-files
check-files: ## Check the files properties.
	@echo "${GREEN}Check the files properties${RESET}"
	@echo "- Uris"
	@find $(ASSETS) -type f -name '*.json' | xargs jq -r '.properties.files | .[] | [.uri] | .[0] | split(".") | .[1]' | sort | uniq -c
	@echo "- Types"
	@find $(ASSETS) -type f -name '*.json' | xargs jq -r '.properties.files' | jq -c '.[] | [.type]' | sort | uniq -c

.PHONY: check-creators
check-creators: ## Check the creators properties.
	@echo "${GREEN}Check the creators properties${RESET}"
	@echo "- Addresses and shares"
	@find $(ASSETS) -type f -name '*.json' | xargs jq '.properties.creators' | jq -c '.[] | [.address,.share]' | sort | uniq -c
	@echo -n "- Sum of the shares: "
	@find $(ASSETS) -type f -name '*.json' | xargs jq '.properties.creators' | jq -c '.[] | [.address,.share]' | sort | uniq | jq '.[1]' | jq -s 'add'


##@ Solana Wallet
.PHONY: sol-create
sol-create: ## Create a developper wallet on Solana (can only be run once).
	solana-keygen new --outfile $(SOL_DEVNET)
	solana config set --keypair $(SOL_DEVNET)
	solana config set --url https://api.devnet.solana.com
	@echo "${GREEN}> New developper wallet created and configured${RESET}"

.PHONY: sol-address
sol-address: ## Get the address of the wallet.
	solana address

.PHONY: sol-balance
sol-balance: ## Get the SOL balance of the wallet.
	solana balance

.PHONY: sol-fund
sol-fund: ## Receive 5 SOL on the wallet.
	solana airdrop 5

##@ Metaplex
.PHONY: mp-install
mp-install: ## Install and configure metaplex.
	@git clone --branch v1.0.0 https://github.com/metaplex-foundation/metaplex.git $(METAPLEX) 2> /dev/null || echo "${GREEN}Metaplex repository already cloned${RESET}${NEW_LINE}"
	
	yarn install --cwd $(METAPLEX)/js/
	@echo "${GREEN}Dependencies have been successfully installed${RESET}${NEW_LINE}"

	@echo -n "${GREEN}Metaplex version installed: ${RESET}"
	@ts-node $(METAPLEX)/js/packages/cli/src/candy-machine-cli.ts --version

.PHONY: mp-upload
mp-upload: ## Upload the NFT assets to Arweave on the devnet (delete the .cache/ folder to run it again).
	ts-node $(METAPLEX)/js/packages/cli/src/candy-machine-cli.ts upload $(ASSETS) --env devnet --keypair $(SOL_DEVNET)
	@echo "${GREEN}Check the transaction on https://explorer.solana.com/?cluster=devnet${RESET}"

.PHONY: mp-verify
mp-verify: ## Verify the uploaded NFT assets on Arweave (devnet)
	ts-node $(METAPLEX)/js/packages/cli/src/candy-machine-cli.ts verify --keypair $(SOL_DEVNET)

.PHONY: mp-candy-machine
mp-candy-machine: ## Create and deploy the candy machine to the devnet
	ts-node $(METAPLEX)/js/packages/cli/src/candy-machine-cli.ts create_candy_machine --env devnet --keypair $(SOL_DEVNET) -p 1
	@echo "${GREEN}Check the transaction on https://explorer.solana.com/?cluster=devnet${RESET}"

.PHONY: mp-update-date
mp-update-date: ## Update the date of the candy machine (date is hardcoded!!).
	ts-node $(METAPLEX)/js/packages/cli/src/candy-machine-cli.ts update_candy_machine --date "13 Dec 2021 00:00:00 GMT" --env devnet --keypair $(SOL_DEVNET)
	@echo "${GREEN}Check the transaction on https://explorer.solana.com/?cluster=devnet${RESET}"

.PHONY: mp-clear-cache
mp-clear-cache: ## This needs to be done if you want to update your NFTs! Then run upload, verify, create, update and update your .env file.
	rm -r .cache/
