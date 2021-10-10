import { ethers } from "hardhat"
const { BigNumber } = require("@ethersproject/bignumber");

async function main() {
  const deployer = await (ethers.provider.getSigner()).getAddress()
  console.log(`deployer = ${deployer}`)

  const MintableERC20 = await ethers.getContractFactory('MintableERC20')
  console.log('Deploying MintableERC20...')
  const token = await MintableERC20.deploy('USDZ Coin', 'USDZ')
  await token.deployed()
  console.log('MintableERC20 deployed:', token.address)

  // const tokenAmount = BigNumber.from('1000000000000000000000')
  // token.mint(tokenAmount, deployer, { gasLimit: 500000 })
  // console.log('minted', tokenAmount.toString())

  // const balance = await token.balanceOf(deployer)
  // console.log('deployer balance:', balance)
}

main()
      .then(() => process.exit(0))
      .catch(error => {
          console.log(error)
          process.exit(1)
      })