const { expect } = require("chai")
const { ethers } = require("hardhat")

const { BigNumber } = require("@ethersproject/bignumber")
const chai = require('chai')

chai.use(require('chai-bignumber')())
chai.use(require('chai-web3-bindings'))


const toBN = function (val) {
  return BigNumber.from(val)
}


const getEvents = async function (tx, name) {
  await tx.wait()
  console.log()
  tx.events.forEach(el => { console.log(el) })
  return receipt.events?.filter((x) => { return x.event == name })
}


const getLastBlockTimestamp = async function () {
  const blockNum = await ethers.provider.getBlockNumber()
  const block = await ethers.provider.getBlock(blockNum)
  return block.timestamp
}

async function sleepUntil(timestamp) {
  const currentTime = await getLastBlockTimestamp()
  await ethers.provider.send('evm_setNextBlockTimestamp', [timestamp])
  ethers.provider.send('evm_mine')
}


describe('Product Hub', function () {
  const BigOne = toBN(10).pow(toBN(18))
  const initBalance = toBN(1000).mul(BigOne)

  const productId = 'product_id'
  const productName = 'Product name'
  const price = toBN(5).mul(BigOne)
  const period = toBN(30 * 24 * 3600) // 30 days
  const metadataUri = 'ipfs://...'

  let signers
  let productOwner
  let user
  let user2
  let token1
  let token2
  // let router;
  let nft
  let hub
  // let tx;
  // let rc;

  beforeEach(async function () {
    signers = await ethers.getSigners()
    owner = signers[0]
    productOwner = signers[1]
    user = signers[2]
    user2 = signers[3]

    const Token = await ethers.getContractFactory('MockCoin')
    const OtherToken = await ethers.getContractFactory('OtherMockCoin')
    token1 = await Token.deploy()
    token2 = await OtherToken.deploy()

    for (let i = 1; i < signers.length; i++) { // skip 0th
      await token1.transfer(signers[i].address, initBalance)
      await token2.transfer(signers[i].address, initBalance)
    }

    ProductsHubFactory = await ethers.getContractFactory('ProductsHub')
    hub = await ProductsHubFactory.deploy()
    await hub.deployed()

    const nftAddress = await hub.nft()
    SubscriptionNFTFactory = await ethers.getContractFactory('SubscriptionNFT')
    nft = await SubscriptionNFTFactory.attach(nftAddress)

    // router = await ethers.getContractAt("IUniswapV2Router02", '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
  })

  it('Create product', async function () {
    // create and check event
    await expect(hub.connect(productOwner).createProduct(productId, productName, token1.address, price, period, metadataUri))
      .to.emit(hub, 'ProductCreated')
      .withArgs(
        productOwner.address,
        productId,
        token1.address,
        productName,
        price,
        period,
        metadataUri
      )

    // check owner
    const products = await hub.getOwnerProductIds(productOwner.address)
    expect(products.length).to.equal(1)
    expect(products[0]).to.equal(productId)

    // check product info
    const [_id, _name, _price, _token, _period, _owner, _uri] = await hub.getProductInfo(productId)
    expect(_id).to.equal(productId)
    expect(_name).to.equal(productName)
    expect(_price).to.equal(price)
    expect(_token).to.equal(token1.address)
    expect(_period).to.equal(period)
    expect(_owner).to.equal(productOwner.address)
    expect(_uri).to.equal(metadataUri)
  })

  it('Subscribe', async function () {
    // create product
    await hub.connect(productOwner).createProduct(productId, productName, token1.address, price, period, metadataUri)

    // checks
    expect(await token1.balanceOf(user.address)).to.equal(initBalance)
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance)
    expect(await hub.findTokenId(productId, user.address)).to.equal(0)

    // subscribe
    const tokenId = 1
    await token1.connect(user).approve(hub.address, initBalance)
    await expect(hub.connect(user).subscribe(productId))
      .to.emit(hub, 'SubscriptionCreated').withArgs(user.address, productId, tokenId)

    // checks
    expect(await nft.ownerOf(tokenId)).to.equal(user.address)
    expect(await token1.balanceOf(user.address)).to.equal(initBalance.sub(price))
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price))
    expect(await hub.findTokenProduct(tokenId)).to.equal(productId)
    expect(await hub.findTokenId(productId, user.address)).to.equal(tokenId)
  })


  it('Renew, renew multiple, burn', async function () {
    // create product
    await hub.connect(productOwner).createProduct(productId, productName, token1.address, price, period, metadataUri)

    // subscribe
    const tokenId = 1
    await token1.connect(user).approve(hub.address, initBalance)
    await hub.connect(user).subscribe(productId)
    let lastPaymentTime = await getLastBlockTimestamp()

    expect(await nft.ownerOf(tokenId)).to.equal(user.address)
    expect(await hub.findTokenId(productId, user.address)).to.equal(tokenId)
    expect(await token1.balanceOf(user.address)).to.equal(initBalance.sub(price))
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price))

    // can't renew too early
    await expect(hub.connect(productOwner).renewSubscription(tokenId))
      .to.be.revertedWith("TOO_EARLY")
    await expect(hub.connect(productOwner).renewProductSubscription(productId, user.address))
      .to.be.revertedWith("TOO_EARLY")

    // sleep until next period and renew (at least: lastPaymentTime + period - 1)
    await sleepUntil(lastPaymentTime + period.toNumber())
    await hub.connect(productOwner).renewProductSubscription(productId, user.address)
    lastPaymentTime = await getLastBlockTimestamp()

    expect(await nft.ownerOf(tokenId)).to.equal(user.address)
    expect(await hub.findTokenId(productId, user.address)).to.equal(tokenId)
    expect(await token1.balanceOf(user.address)).to.equal(initBalance.sub(price.mul(2)))
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price.mul(2)))
    // TODO: check time of last renewal

    const periodCount = 5
    // renew multiple periods
    await sleepUntil(lastPaymentTime + period.toNumber() * periodCount)
    await hub.connect(productOwner).renewProductSubscription(productId, user.address)
    lastPaymentTime = await getLastBlockTimestamp()

    expect(await nft.ownerOf(tokenId)).to.equal(user.address)
    expect(await hub.findTokenId(productId, user.address)).to.equal(tokenId)
    expect(await token1.balanceOf(user.address)).to.equal(initBalance.sub(price.mul(2 + periodCount)))
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price.mul(2 + periodCount)))

    // leave wallet empty
    const balance = await token1.balanceOf(user.address)
    await token1.connect(user).transfer(owner.address, balance)
    expect(await token1.balanceOf(user.address)).to.equal(0)

    // try to renew and burn NFT
    await sleepUntil(lastPaymentTime + period.toNumber())
    await expect(hub.connect(productOwner).renewProductSubscription(productId, user.address))
      .to.emit(hub, 'SubscriptionCancelled').withArgs(user.address, productId, tokenId, productOwner.address)

    // check user don't have NFT
    await expect(nft.ownerOf(tokenId)).to.be.revertedWith("ERC721: owner query for nonexistent token")
    expect(await hub.findTokenId(productId, user.address)).to.equal(0)
    expect(await token1.balanceOf(user.address)).to.equal(0)
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price.mul(2 + periodCount)))
  })


  it('Transfer subscription', async function () {
    // create product
    await hub.connect(productOwner).createProduct(productId, productName, token1.address, price, period, metadataUri)

    // subscribe
    const tokenId = 1
    await token1.connect(user).approve(hub.address, initBalance)
    await hub.connect(user).subscribe(productId)
    let lastPaymentTime = await getLastBlockTimestamp()

    expect(await nft.ownerOf(tokenId)).to.equal(user.address)
    expect(await hub.findTokenId(productId, user.address)).to.equal(tokenId)
    expect(await hub.findTokenId(productId, user2.address)).to.equal(0)
    expect(await token1.balanceOf(user.address)).to.equal(initBalance.sub(price))
    expect(await token1.balanceOf(user2.address)).to.equal(initBalance)
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price))

    // transfer
    await nft.connect(user).transferFrom(user.address, user2.address, tokenId)

    expect(await nft.ownerOf(tokenId)).to.equal(user2.address)
    expect(await hub.findTokenId(productId, user.address)).to.equal(0)
    expect(await hub.findTokenId(productId, user2.address)).to.equal(tokenId)

    // renew to charge a new user
    await sleepUntil(lastPaymentTime + period.toNumber())
    await token1.connect(user2).approve(hub.address, initBalance)
    await expect(hub.connect(productOwner).renewProductSubscription(productId, user.address))
      .to.be.revertedWith('NOT_SUBSCRIBED')
    await expect(hub.connect(productOwner).renewProductSubscription(productId, user2.address))
      .to.emit(hub, 'SubscriptionRenewed').withArgs(user2.address, productId, tokenId, productOwner.address)

    expect(await nft.ownerOf(tokenId)).to.equal(user2.address)
    expect(await hub.findTokenId(productId, user.address)).to.equal(0)
    expect(await hub.findTokenId(productId, user2.address)).to.equal(tokenId)
    expect(await token1.balanceOf(user.address)).to.equal(initBalance.sub(price))
    expect(await token1.balanceOf(user2.address)).to.equal(initBalance.sub(price))
    expect(await token1.balanceOf(productOwner.address)).to.equal(initBalance.add(price.mul(2)))
  })

  xit('Multple renewals', async function () {
    // TODO: implement
  })

  xit('Cancel', async function () {
    // TODO: implement
  })
});
