# Core

This reporisotry contains core smart contracts.

- A user can create and manage organizations.  
- An organization can have multiple subscriptions.  
- A client can view organization subscriptions, get subscription cost, and subscribe to it.  


### Set up

1. Create `.env` and set Alchemy API key to ALCHEMY_API_KEY  
2. Set Ethereum address private key to PRIVATE_KEY in `.env`  
3. Install deps `npm install`  

### Run

* Run new node on localhost: `npx hardhat node`  
* Run mainnet fork node on localhost: `npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/[API_KEY]`  
* Run tests: `npx hardhat --network localhost tests/subscriptions.ts`  
* Deploy: `npx hardhat --network ropsten run scripts/deploy.ts`  
