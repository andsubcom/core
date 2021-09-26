const { expect } = require("chai");
const { ethers } = require("hardhat");

const chai = require('chai');
const { BigNumber } = require("@ethersproject/bignumber");
chai.use(require('chai-bignumber')());
chai.use(require('chai-web3-bindings'));


const toBN = function(val) {
  return BigNumber.from(val);
}


const getEvents = async function(tx, name) {
  await tx.wait();
  console.log()
  tx.events.forEach(el => {console.log(el)});
  return receipt.events?.filter((x) => {return x.event == name});
}


const getLastBlockTimestamp = async function () {
  const blockNum = await ethers.provider.getBlockNumber();
  const block = await ethers.provider.getBlock(blockNum);
  const timestamp = block.timestamp;
  return timestamp;
}


describe("Subscriptions Hub", function () {
  const BigOne = toBN(10).pow(toBN(18));
  const everyoneBalance = toBN(1000).mul(BigOne);
  let signers;
  let owner;
  let coin;
  let otherCoin;
  let router;
  let nft;
  let hub;
  let tx;
  let rc;

  beforeEach(async function () {
    signers = await ethers.getSigners();
    owner = signers[0];

    MockCoin = await ethers.getContractFactory("MockCoin");
    OtherMockCoin = await ethers.getContractFactory("OtherMockCoin");
    coin = await MockCoin.deploy();
    otherCoin = await OtherMockCoin.deploy();

    for(let i=1; i<signers.length; i++) { // skip 0th
      await coin.transfer(signers[i].address, everyoneBalance);
      await otherCoin.transfer(signers[i].address, everyoneBalance);
    }

    SubscriptionsHubFactory = await ethers.getContractFactory("SubscriptionsHub");
    hub = await SubscriptionsHubFactory.deploy();
    await hub.deployed();
    
    const nftAddress = await hub.nft();
    SubscriptionTicketNFTFactory = await ethers.getContractFactory("SubscriptionTicketNFT");
    nft = await SubscriptionTicketNFTFactory.attach(nftAddress);

    router = await ethers.getContractAt("IUniswapV2Router02", '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
  });

  // it("Create organization", async function () {
  //   const organizationName = "some-organization";
  //   await expect(hub.createOrganization(organizationName))
  //     .to.emit(hub, "OrganizationCreated")
  //     .withArgs(
  //       toBN(0),
  //       owner.address,
  //       organizationName,
  //     );
  // });
  //
  // it("Create subscription", async function () {
  //   const organizationName = "some-organization";
  //   const subscriptionName = "some-organization";
  //   await expect(hub.createOrganization(organizationName))
  //     .to.emit(hub, "OrganizationCreated")
  //     .withArgs(
  //       toBN(0),
  //       owner.address,
  //       organizationName,
  //     );
  //   const price = toBN(1).mul(BigOne);
  //   const period = 30*24*3600;
  //   await expect(hub.createSubscription(toBN(0), subscriptionName, coin.address, price, period))
  //     .to.emit(hub, "SubscriptionCreated")
  //     .withArgs(
  //       toBN(0),
  //       toBN(0),
  //       coin.address,
  //       price,
  //       period,
  //       subscriptionName
  //     );
  // });
  //
  // it("Buy subscription and transfer and renew by admin", async function () {
  //   const organizationName = "some-organization";
  //   const subscriptionName = "some-organization";
  //   const organizationId = toBN(0);
  //   const subscriptionId = toBN(0);
  //   const user1 = signers[1];
  //   const user2 = signers[2];
  //   await expect(hub.createOrganization(organizationName))
  //     .to.emit(hub, "OrganizationCreated")
  //     .withArgs(
  //       organizationId,
  //       owner.address,
  //       organizationName,
  //     );
  //   const price = toBN(1).mul(BigOne);
  //   const period = 30*24*3600;
  //   await expect(hub.createSubscription(organizationId, subscriptionName, coin.address, price, period))
  //     .to.emit(hub, "SubscriptionCreated")
  //     .withArgs(
  //       organizationId,
  //       subscriptionId,
  //       coin.address,
  //       price,
  //       period,
  //       subscriptionName
  //     );
  //
  //   expect(await nft.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);
  //   expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);
  //
  //   const tokenId = toBN(0);
  //   const allowAutoExtend = true;
  //   await coin.connect(user1).approve(hub.address, price);
  //   await hub.connect(user1).buySubscription(subscriptionId, allowAutoExtend);
  //
  //   expect(await nft.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(true);
  //   expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(true);
  //
  //   await nft.connect(user1).transferFrom(user1.address, user2.address, tokenId);
  //
  //   expect((await nft.getUserTokenIds(user1.address)).length).to.be.equal(0);
  //   expect((await nft.getUserTokenIds(user2.address)).length).to.be.equal(1);
  //   expect((await nft.getUserTokenIds(user2.address))[0]).to.be.equal(tokenId);
  //
  //   expect((await nft.getUserSubscriptionTokenIds(user1.address, subscriptionId)).length).to.be.equal(0);
  //   expect((await nft.getUserSubscriptionTokenIds(user2.address, subscriptionId)).length).to.be.equal(1);
  //   expect((await nft.getUserSubscriptionTokenIds(user2.address, subscriptionId))[0]).to.be.equal(tokenId);
  //
  //   expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);
  //   expect(await hub.checkUserHasActiveSubscription(user2.address, subscriptionId)).to.be.equal(true);
  //
  //   await coin.connect(user2).approve(hub.address, price);
  //
  //   let [, startTimestamp, endTimestamp, ] = await nft.getTokenInfo(tokenId);
  //   let endTimestampNum = endTimestamp.toNumber();
  //   await expect(hub.extendSubscription(tokenId)).to.be.revertedWith("AUTO_BY_ADMIN_EXTEND_TOO_EARLY");
  //
  //   await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum - 24*3600]);
  //   ethers.provider.send('evm_mine');
  //
  //   await hub.extendSubscription(tokenId);  // extend is made by the admin
  //   await expect(hub.extendSubscription(tokenId)).to.be.revertedWith("AUTO_BY_ADMIN_EXTEND_TOO_EARLY");  // cannot be done twice by the admin
  //
  //   await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum + 24*3600]);
  //   ethers.provider.send('evm_mine');
  //
  //   // subscription is still active
  //   expect(await hub.checkUserHasActiveSubscription(user2.address, subscriptionId)).to.be.equal(true);
  // });

  it("Buy subscription and transfer and renew by admin for other token", async function () {
    const poolLiquidityAmount = BigOne.mul(toBN(100));
    let ts = await getLastBlockTimestamp();
    await coin.approve(router.address, poolLiquidityAmount);
    await otherCoin.approve(router.address, poolLiquidityAmount);
    await router.addLiquidity(coin.address, otherCoin.address, poolLiquidityAmount, poolLiquidityAmount, poolLiquidityAmount, poolLiquidityAmount, owner.address, ts + 3600);

    const organizationName = "some-organization";
    const subscriptionName = "some-organization";
    const organizationId = toBN(0);
    const subscriptionId = toBN(0);
    const user1 = signers[1];
    const user2 = signers[2];
    await expect(hub.createOrganization(organizationName))
      .to.emit(hub, "OrganizationCreated")
      .withArgs(
        organizationId,
        owner.address,
        organizationName,
      );
    const price = toBN(1).mul(BigOne);
    const period = 30*24*3600;
    await expect(hub.createSubscription(organizationId, subscriptionName, coin.address, price, period))
      .to.emit(hub, "SubscriptionCreated")
      .withArgs(
        organizationId,
        subscriptionId,
        coin.address,
        price,
        period,
        subscriptionName
      );

    expect(await nft.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);
    expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);

    const tokenId = toBN(0);
    const allowAutoExtend = true;
    const otherCoinMaxAmount = price.mul(toBN(2));
    await otherCoin.connect(user1).approve(hub.address, otherCoinMaxAmount);
    await hub.connect(user1).buySubscriptionByAnyToken(
        subscriptionId,
        allowAutoExtend,
        otherCoin.address,
        otherCoinMaxAmount,
        ts+3600,
    );

    expect(await nft.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(true);
    expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(true);

    await nft.connect(user1).transferFrom(user1.address, user2.address, tokenId);

    expect((await nft.getUserTokenIds(user1.address)).length).to.be.equal(0);
    expect((await nft.getUserTokenIds(user2.address)).length).to.be.equal(1);
    expect((await nft.getUserTokenIds(user2.address))[0]).to.be.equal(tokenId);

    expect((await nft.getUserSubscriptionTokenIds(user1.address, subscriptionId)).length).to.be.equal(0);
    expect((await nft.getUserSubscriptionTokenIds(user2.address, subscriptionId)).length).to.be.equal(1);
    expect((await nft.getUserSubscriptionTokenIds(user2.address, subscriptionId))[0]).to.be.equal(tokenId);

    expect(await hub.checkUserHasActiveSubscription(user1.address, subscriptionId)).to.be.equal(false);
    expect(await hub.checkUserHasActiveSubscription(user2.address, subscriptionId)).to.be.equal(true);

    await otherCoin.connect(user2).approve(hub.address, otherCoinMaxAmount);

    let [, startTimestamp, endTimestamp, ] = await nft.getTokenInfo(tokenId);
    let endTimestampNum = endTimestamp.toNumber();

    await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum - 24*3600]);
    ethers.provider.send('evm_mine');

    await hub.extendSubscriptionByAnyToken(tokenId, otherCoin.address, otherCoinMaxAmount, endTimestampNum + 24*3600+3600);  // extend is made by the admin

    await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum + 24*3600]);
    ethers.provider.send('evm_mine');

    // subscription is still active
    expect(await hub.checkUserHasActiveSubscription(user2.address, subscriptionId)).to.be.equal(true);
  });
});
