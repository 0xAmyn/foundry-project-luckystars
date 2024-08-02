# Makefile for deploying smart contracts using Foundry on Arbitrum Sepolia
# Load environment variables from .env file
include .env

# Default network to use for deployment
RPC_URL := $(ARB_SEPOLIA_RPC_URL)
PRIVATE_KEY := $(PRIVATE_KEY)
ETHERSCAN_API_KEY := $(ARB_ETHERSCAN_API_KEY)
GAS_LIMIT := 1000000

# Contract-specific details
CONTRACT_NAME := CelestialNFT   
CONTRACT_ADDRESS := 0x1eadac3e03d8c15fc2ca87f78b3d9893ceb0108d

# Paths and files
SRC_DIR := src
OUT_DIR := out
SCRIPT := script/DeployCelestialNFT.s.sol

# Foundry commands
FORGE := forge
CAST := cast

# Default target: compile and deploy
all: compile deploy

# Compile smart contracts
compile:
	$(FORGE) build

# Run the deployment script on Arbitrum Sepolia
deploy: compile
	$(FORGE) script $(SCRIPT) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--verify --etherscan-api-key $(ETHERSCAN_API_KEY) \
		--broadcast -vvvv

verify:
	$(FORGE) verify-contract \
		--chain-id $(shell cast chain-id --rpc-url $(RPC_URL)) \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		$(CONTRACT_ADDRESS) $(CONTRACT_NAME)

# Clean the build files
clean:
	rm -rf $(OUT_DIR)

test-onchain:
	$(FORGE) test \
	--rpc-url $(RPC_URL)
	-vvvvv

# cast call 
call-raffle:
	$(CAST) send $(CONTRACT_ADDRESS) "enterRaffle()" \
	--value 0.001ether \
	--private-key $(PRIVATE_KEY) \
	--rpc-url $(RPC_URL) \	

# Help message
help:
	@echo "Makefile for deploying smart contracts using Foundry on Arbitrum Sepolia"
	@echo ""
	@echo "Usage:"
	@echo "  make all       - Compile and deploy contracts"
	@echo "  make compile   - Compile the contracts"
	@echo "  make deploy    - Deploy the contracts using the deployment script"
	@echo "  make clean     - Remove all build artifacts"
	@echo "  make help      - Display this help message"

.PHONY: all compile deploy clean help
