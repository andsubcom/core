const { expect } = require("chai");
const { ethers } = require("hardhat");

const chai = require('chai');
const { BigNumber } = require("@ethersproject/bignumber");
chai.use(require('chai-bignumber')());
chai.use(require('chai-web3-bindings'));


const toBN = function(val) {
  return BigNumber.from(val);
}


describe("Subscriptions Hub", function () {
  const BigOne = toBN(10).pow(toBN(18));
  const everyoneBalance = toBN(1000).mul(BigOne);
  let signers;
  let owner;
  let treasury;
  let coin;
  let nft;
  let hub;

  beforeEach(async function () {
    signers = await ethers.getSigners();
    owner = signers[0];
    treasury = signers[signers.length-1];

    MockCoin = await ethers.getContractFactory("MockCoin");
    coin = await MockCoin.deploy();

    for(let i=1; i<signers.length; i++) { // skip 0th
      await coin.transfer(signers[i].address, everyoneBalance);
    }  

    SubscriptionsHubFactory = await ethers.getContractFactory("SubscriptionsHub");
    hub = await SubscriptionsHubFactory.deploy(treasury.address);
    nft = await hub.nft();
  })

  it("Create organization", async function () {
    const name = "some-organization";
    await hub.createOrganization(name);
  });
});
