# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update
remappings:; forge remappings > remappings.txt

# Build & test
build  :; forge clean && forge build --optimize --optimizer-runs 1000000
test   :; forge clean && forge test --optimize --optimizer-runs 1000000 -v
test-debug   :; forge clean && forge test --optimize --optimizer-runs 1000000 -vv
test-trace   :; forge clean && forge test --optimize --optimizer-runs 1000000 -vvv
gas-report :; forge clean && forge test --optimize --optimizer-runs 1000000 --gas-report
clean  :; forge clean
snapshot :; forge clean && forge snapshot --optimize --optimizer-runs 1000000

# Hardhat
deploy-local :; npx hardhat compile && npx hardhat deploy --network localhost --env localhost
deploy-testnet :; npx hardhat compile && npx hardhat deploy --network rinkeby --env testnet
deploy-testnet-kovan :; npx hardhat compile && npx hardhat deploy --network kovan --env testnet
deploy-testnet-goerli :; npx hardhat compile && npx hardhat deploy --network goerli --env testnet
deploy-mainnet :; npx hardhat compile && npx hardhat deploy --network mainnet --env mainnet


#Test
execute-trust-kovan :; npx hardhat execute --network rinkeby --type trust --origin rinkeby --destination kovan 
execute-trust-rinkeby :; npx hardhat execute --network kovan --type trust --origin kovan --destination rinkeby 

execute-test-first :; npx hardhat execute --network rinkeby --type retry --origin rinkeby --destination kovan --action first 
execute-test-first-kovan :; npx hardhat execute --network kovan --type retry --origin kovan --destination rinkeby --action first 
execute-test-giveAccess :; npx hardhat execute --network kovan --type retry --origin rinkeby --destination kovan --action giveAccess 
execute-test-retry :; npx hardhat execute --network kovan --type retry --origin rinkeby --destination kovan --action retry 