import * as dotenv from 'dotenv'
import '@nomiclabs/hardhat-waffle'
import "@nomiclabs/hardhat-etherscan";
import { HardhatUserConfig } from 'hardhat/types'

dotenv.config()
const accounts = [ process.env.PRIVATE_KEY! ]

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: accounts
    },
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: accounts
    },
  },
  solidity: "0.8.6",
}

export default config