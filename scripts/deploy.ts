import { ethers } from "hardhat"

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()

  const ProductHub = await ethers.getContractFactory('ProductHub')
  console.log('Deploying ProductHub...')
  const hub = await ProductHub.deploy()
  await hub.deployed()
  console.log('ProductHub deployed:', hub.address)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })