import { ethers } from "hardhat"

const HUB_ADDRESS = '0xA20B982b7a534b4a1e8c71A45ADbfe8faeed2cff'
const TOKEN_ADDRESS = '0x6ef6f7ca5fb523c0cf8f793cd9c3eef228e86679'

const PERIOD_MONTH = 2629743
const PERIOD_YEAR = 31556926

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()
  // const anotherUser = await (await ethers.getSigners())[1]
  const options = { gasLimit: 500000 }

  const token = await ethers.getContractAt('XCoin', TOKEN_ADDRESS)
  const hub = await ethers.getContractAt('SubscriptionsHub', HUB_ADDRESS)

  // create org
  // await (await hub.createOrganization('Awake', options)).wait()
  // console.log('Organization created')

  // const organizationId = 0
  // const org = await hub.getOrganizationInfo(organizationId, options)
  // console.log('organization =', org)

  // // create products
  // await (await hub.createSubscription(organizationId, 'Pro Monthly', PAYABLE_TOKEN_ADDRESS, 10, PERIOD_MONTH, options)).wait()
  // await (await hub.createSubscription(organizationId, 'Pro Annual', PAYABLE_TOKEN_ADDRESS, 100, PERIOD_YEAR, options)).wait()

  // show product ids
  // const subs = await hub.getAllsubscriptionsForOrganization(organizationId, options)
  // console.log(subs)

  // // mint token
  // const address = anotherUser.getAddress()
  // const tokenAmount = 10000
  // await (await token.connect(deployer).mint(address, tokenAmount, options)).wait()
  // console.log(`minted ${tokenAmount} USDX to ${address}`)
  
  // // check token balance
  // const balance = await token.balanceOf(address, options)
  // console.log(`balance of ${address} is ${balance.toString()} USDX`)

  // // subscribe
  // const cost = 10
  // await (await token.connect(anotherUser).approve(hub.address, cost, options)).wait()
  // console.log(`${address} approved ${cost} USDX to ${hub.address}`)
  // await (await hub.connect(anotherUser).buySubscription(0, options)).wait()
  // console.log(`${anotherUser} subscribed to sub 0!`)

  // // check active sub
  // const hasAccess = await hub.checkUserHasActiveSubscription(address, 0, options)
  // console.log(`${address} has access to sub 0:`, hasAccess)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })