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


describe("Products Hub", function () {
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

    ProductsHubFactory = await ethers.getContractFactory("ProductsHub");
    hub = await ProductsHubFactory.deploy();
    await hub.deployed();
    
    const nftAddress = await hub.nft();
    SubscriptionNFTFactory = await ethers.getContractFactory("SubscriptionNFT");
    nft = await SubscriptionNFTFactory.attach(nftAddress);

    router = await ethers.getContractAt("IUniswapV2Router02", '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
  });

  it("Create product", async function () {
    const productId = "some_organization";
    const productName = "some organization";
    const price = toBN(1).mul(BigOne);
    const period = 30*24*3600;
    await expect(hub.createProduct(productId, productName, coin.address, price, period))
      .to.emit(hub, "ProductCreated")
      .withArgs(
          signers[0].address,
          productId,
          coin.address,
          price,
          period,
          productName
      );
  });

  it("Buy product and transfer and renew by admin", async function () {
    const productId = "some_product";
    const productName = "some-product";
    const organizationId = toBN(0);
    const subscriptionId = toBN(0);
    const user1 = signers[1];
    const user2 = signers[2];
    const price = toBN(1).mul(BigOne);
    const period = 30*24*3600;
    await expect(hub.createProduct(productId, productName, coin.address, price, period))
      .to.emit(hub, "ProductCreated")
      .withArgs(
          signers[0].address,
          productId,
          coin.address,
          price,
          period,
          productName
      );

    expect(await nft.checkUserHasActiveSubscription(user1.address, productId)).to.be.equal(false);
    expect(await hub.checkUserHasActiveSubscription(user1.address, productId)).to.be.equal(false);

    const tokenId = toBN(0);
    const allowAutoExtend = true;
    await coin.connect(user1).approve(hub.address, price);
    await hub.connect(user1).subscribe(productId, allowAutoExtend);

    expect(await nft.checkUserHasActiveSubscription(user1.address, productId)).to.be.equal(true);
    expect(await hub.checkUserHasActiveSubscription(user1.address, productId)).to.be.equal(true);

    await nft.connect(user1).transferFrom(user1.address, user2.address, tokenId);

    expect((await nft.getUserTokenIds(user1.address)).length).to.be.equal(0);
    expect((await nft.getUserTokenIds(user2.address)).length).to.be.equal(1);
    expect((await nft.getUserTokenIds(user2.address))[0]).to.be.equal(tokenId);

    expect((await nft.getUserProductSubscriptionIds(user1.address, productId)).length).to.be.equal(0);
    expect((await nft.getUserProductSubscriptionIds(user2.address, productId)).length).to.be.equal(1);
    expect((await nft.getUserProductSubscriptionIds(user2.address, productId))[0]).to.be.equal(tokenId);

    expect(await hub.checkUserHasActiveSubscription(user1.address, productId)).to.be.equal(false);
    expect(await hub.checkUserHasActiveSubscription(user2.address, productId)).to.be.equal(true);

    await coin.connect(user2).approve(hub.address, price);

    let [, startTimestamp, endTimestamp, ] = await nft.getTokenInfo(tokenId);
    let endTimestampNum = endTimestamp.toNumber();
    await expect(hub.extendSubscription(tokenId)).to.be.revertedWith("AUTO_BY_ADMIN_EXTEND_TOO_EARLY");

    await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum - 24*3600]);
    ethers.provider.send('evm_mine');

    await hub.extendSubscription(tokenId);  // extend is made by the admin
    await expect(hub.extendSubscription(tokenId)).to.be.revertedWith("AUTO_BY_ADMIN_EXTEND_TOO_EARLY");  // cannot be done twice by the admin

    await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum + 24*3600]);
    ethers.provider.send('evm_mine');

    // product is still active
    expect(await hub.checkUserHasActiveSubscription(user2.address, productId)).to.be.equal(true);
  });

  // it("Buy product and transfer and renew by admin for other token", async function () {
  //   const poolLiquidityAmount = BigOne.mul(toBN(100));
  //   let ts = await getLastBlockTimestamp();
  //   await coin.approve(router.address, poolLiquidityAmount);
  //   await otherCoin.approve(router.address, poolLiquidityAmount);
  //   await router.addLiquidity(coin.address, otherCoin.address, poolLiquidityAmount, poolLiquidityAmount, poolLiquidityAmount, poolLiquidityAmount, owner.address, ts + 3600);
  //
  //   const organizationName = "some-organization";
  //   const productName = "some-organization";
  //   const organizationId = toBN(0);
  //   const productId = toBN(0);
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
  //   await expect(hub.createProduct(organizationId, productName, coin.address, price, period))
  //     .to.emit(hub, "ProductCreated")
  //     .withArgs(
  //       organizationId,
  //       productId,
  //       coin.address,
  //       price,
  //       period,
  //       productName
  //     );
  //
  //   expect(await nft.checkUserHasActiveProduct(user1.address, productId)).to.be.equal(false);
  //   expect(await hub.checkUserHasActiveProduct(user1.address, productId)).to.be.equal(false);
  //
  //   const tokenId = toBN(0);
  //   const allowAutoExtend = true;
  //   const otherCoinMaxAmount = price.mul(toBN(2));
  //   await otherCoin.connect(user1).approve(hub.address, otherCoinMaxAmount);
  //   await hub.connect(user1).buyProductByAnyToken(
  //       productId,
  //       allowAutoExtend,
  //       otherCoin.address,
  //       otherCoinMaxAmount,
  //       ts+3600,
  //   );
  //
  //   expect(await nft.checkUserHasActiveProduct(user1.address, productId)).to.be.equal(true);
  //   expect(await hub.checkUserHasActiveProduct(user1.address, productId)).to.be.equal(true);
  //
  //   await nft.connect(user1).transferFrom(user1.address, user2.address, tokenId);
  //
  //   expect((await nft.getUserTokenIds(user1.address)).length).to.be.equal(0);
  //   expect((await nft.getUserTokenIds(user2.address)).length).to.be.equal(1);
  //   expect((await nft.getUserTokenIds(user2.address))[0]).to.be.equal(tokenId);
  //
  //   expect((await nft.getUserProductTokenIds(user1.address, productId)).length).to.be.equal(0);
  //   expect((await nft.getUserProductTokenIds(user2.address, productId)).length).to.be.equal(1);
  //   expect((await nft.getUserProductTokenIds(user2.address, productId))[0]).to.be.equal(tokenId);
  //
  //   expect(await hub.checkUserHasActiveProduct(user1.address, productId)).to.be.equal(false);
  //   expect(await hub.checkUserHasActiveProduct(user2.address, productId)).to.be.equal(true);
  //
  //   await otherCoin.connect(user2).approve(hub.address, otherCoinMaxAmount);
  //
  //   let [, startTimestamp, endTimestamp, ] = await nft.getTokenInfo(tokenId);
  //   let endTimestampNum = endTimestamp.toNumber();
  //
  //   await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum - 24*3600]);
  //   ethers.provider.send('evm_mine');
  //
  //   await hub.extendProductByAnyToken(tokenId, otherCoin.address, otherCoinMaxAmount, endTimestampNum + 24*3600+3600);  // extend is made by the admin
  //
  //   await ethers.provider.send('evm_setNextBlockTimestamp', [endTimestampNum + 24*3600]);
  //   ethers.provider.send('evm_mine');
  //
  //   // product is still active
  //   expect(await hub.checkUserHasActiveProduct(user2.address, productId)).to.be.equal(true);
  // });
});
