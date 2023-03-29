require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("solidity-coverage");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("dotenv").config();

module.exports = {
  defaultNetwork: "hardhat",
  solidity: "0.8.18",
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1,
    },
  },
  solidity: {
    compilers: [{ version: "0.8.7" }],
  },
  gasReporter: {
    enabled: false,
  },
};
