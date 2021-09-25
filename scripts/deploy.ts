import { ethers } from "hardhat"

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()

  const Subscriptions = await ethers.getContractFactory('Subscriptions')
  console.log('Deploying Subscriptions...')
  const subscriptions = await Subscriptions.deploy()
  await subscriptions.deployed()
  console.log('Subscriptions deployed:', subscriptions.address)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })