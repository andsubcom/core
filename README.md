# Core

Core smart contracts.

## Interaction flow example

### Create subscription

Some user creates new organization and subscripition:

```js
const organizationName = "SuperCompany"; 
await hub.createOrganization(organizationName);
const organizationId = ...; // from event
const subscriptionName = "Gold";
const price = toBN(10).mul(toBN(18));
const period = 30*24*3600;
await hub.createSubscription(organizationId, subscriptionName, coin.address, price, period);
```

### Buy subscription

Other user buys the subscription:

```js
const allowAutoExtend = true;
await coin.connect(user1).approve(hub.address, price);
await hub.connect(user1).buySubscription(subscriptionId, allowAutoExtend);
```



## Description

### Organization



- Organizations management.  
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
