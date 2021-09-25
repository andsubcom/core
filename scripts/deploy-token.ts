import { ethers } from "hardhat"
const { BigNumber } = require("@ethersproject/bignumber");

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()

  const XCoin = await ethers.getContractFactory('XCoin')
  console.log('Deploying XCoin...')
  const xcoin = await XCoin.deploy()
  await xcoin.deployed()
  console.log('XCoin deployed:', xcoin.address)

  const tokenAmount = BigNumber.from('1000000000000000000000')
  xcoin.mint(tokenAmount, deployer, { gasLimit: 500000 })
  console.log('minted', tokenAmount.toString())

  const balance = await xcoin.balanceOf(deployer)
  console.log('deployer balance:', balance)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })