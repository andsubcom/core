import { ethers } from "hardhat"

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()

  const ProductsHub = await ethers.getContractFactory('ProductsHub')
  console.log('Deploying ProductsHub...')
  const hub = await ProductsHub.deploy()
  await hub.deployed()
  console.log('ProductsHub deployed:', hub.address)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })