import { ethers } from "hardhat"

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()

  const SubscriptionsHub = await ethers.getContractFactory('SubscriptionsHub')
  console.log('Deploying SubscriptionsHub...')
  const hub = await SubscriptionsHub.deploy()
  await hub.deployed()
  console.log('SubscriptionsHub deployed:', hub.address)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })