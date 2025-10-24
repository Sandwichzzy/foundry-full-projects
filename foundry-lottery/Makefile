-include .env

.PHONY:  all test clean deploy fund help install snapshot format anvil deploy-sepolia

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.4.0 && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 && forge install foundry-rs/forge-std@v1.11.0 && forge install transmissions11/solmate@v6

# Update Dependencies
update:; forge update

build :; forge build 

test :; forge test

snapshot :; forge snapshot

format :; forge fmt 

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


# debug :; forge test --debug --mt method
# coverage :; forge coverage --report debug > coverage.txt
# verify :; forge verify-contract 0xA464d41eE745af9274305D455fD0274Bd5669F8B src/Raffle.sol:Raffle --etherscan-api-key $(ETHERSCAN_API_KEY) --rpc-url $(SEPOLIA_RPC_URL) --show-standard-json-input > json.json
# wallet :; cast wallet import <accountName> --interactive


NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
NETWORK_SEPOLIA:= --rpc-url $(SEPOLIA_RPC_URL) --account devWallet --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_SEPOLIA)


deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)