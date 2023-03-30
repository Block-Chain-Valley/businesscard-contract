const { network } = require("hardhat")

const FIRST_MINT_PRICE = ethers.utils.parseEther("1")
const MINT_PRICE = ethers.utils.parseEther("0.2")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId

  log("Deploying BusinessCardBase contract to network: " + chainId)

  if (chainId == 31337) {
    log("Local network detected")
    await deploy("BusinessCardBase", {
      from: deployer,
      log: true,
      args: [],
    })
  }
}
module.exports.tags = ["all", "mocks"]
