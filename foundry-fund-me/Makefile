-include .env

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
.PHONY: all test clean deploy fund help install snapshot format anvil deploy-sepolia 

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && forge install foundry-rs/forge-std@v1.8.2

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast


deploy-sepolia:
	@forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL)  --broadcast  -vvvv

# --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

# For deploying Interactions.s.sol:FundFundMe as well as for Interactions.s.sol:WithdrawFundMe we have to include a sender's address `--sender <ADDRESS>`
SENDER_ADDRESS := <sender's address>
 
fund:
	@forge script script/Interactions.s.sol:FundFundMe --sender $(SENDER_ADDRESS) $(NETWORK_ARGS)

withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe --sender $(SENDER_ADDRESS) $(NETWORK_ARGS)