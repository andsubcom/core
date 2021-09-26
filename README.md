# ⚙ Core

Core smart contracts.
Gives frictionless auto-renewal subscriptions to any service.

Just create your organization in the `SubscriptionsHub`.
Describe subscriptions variants e.g.:

| Type | Period | Price |
|---|---|---|
| GOLD  |  1 week | 10 USDT  |
| GOLD  |  1 month  |  25 USDT |
| GOLD  |  1 year  | 200 USDT  |
| PLATINUM  |  1 week | 30 USDT  |
| PLATINUM  |  1 month  |  60 USDT |
| PLATINUM  |  1 year  | 500 USDT  |

User selects the subscription and buy it setting the allowAutoRenewal flag.

If user wants auto-renewal he may set big erc20 allowance, so the admin of the contract will be able to automatically withdraw the next payment when the subscription period end (but not earlier than 1 day before the expiration).

Subscription ticket is simple NFT-Token so Users may trade it. 

## Development RoadMap

- [x] Organizations registry.
- [x] Subscriptions registry.
- [x] NFT contract for subscription-ticket.
- [x] Subscription selling for payable token.
- [x] Subscription auto renewal by user choice.
- [ ] Streaming subscriptions - pay for usage per second.
- [ ] Pay by any token (via Zerion DEX API and 1inch).
- [ ] Pay on any blockchain (via CrossChain bridge).
- [ ] Custom NFT picture.

## Deployed

### Ropsten

### SubscriptionsHub
Address: `0xF61C6cD6FEa4E407651d94837816aD0f8be350E5`

Verified Code:
https://ropsten.etherscan.io/address/0xF61C6cD6FEa4E407651d94837816aD0f8be350E5#code

### SubscriptionTicketNFT
Address: `0xaE077AD19893988c1D7aAa499FaBbadE99D6Feee`

Verified Code:
https://ropsten.etherscan.io/address/0xae077ad19893988c1d7aaa499fabbade99d6feee#code


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

### Check subscription

```js
expect(await nft.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(true);

expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(true);
```

### Transfer subscription as an ERC721 NFT token

Transfer NFT

```js
await nft.connect(user1).transferFrom(user1.address, user2.address, tokenId);
```

Check subscription:

```js
expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);

expect(await hub.checkUserHasActiveSubscription(user2.address, subscriptionId)).to.be.equal(true);
```

### Transfer subscription as an ERC721 NFT token

Transfer NFT

```js
await nft.connect(user1).transferFrom(user1.address, user2.address, tokenId);
```

Check subscription:

```js
expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);

expect(await hub.checkUserHasActiveSubscription(user2.address, subscriptionId)).to.be.equal(true);
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
