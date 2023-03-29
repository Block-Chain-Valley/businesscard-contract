const { assert, expect } = require("chai")
const { ethers, deployments, getNamedAccounts } = require("hardhat")

developmentChains = ["hardhat", "localhost"]
FIRST_MINT_PRICE = ethers.utils.parseEther("1")
MINT_PRICE = ethers.utils.parseEther("0.2")

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("BusinessCardTesting", () => {
      let deployer
      beforeEach(async () => {
        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        thirdParty = accounts[1]
        await deployments.fixture(["all"])
        businessCard = await ethers.getContract("BusinessCard")
      })

      describe("constructor", () => {
        it("initializes first mint price /  mint price properly", async () => {
          const firstMintPrice = await businessCard.getFirstMintPrice()
          const mintPrice = await businessCard.getMintPrice()
          assert.equal(Number(firstMintPrice), Number(FIRST_MINT_PRICE))
          assert.equal(Number(mintPrice), Number(MINT_PRICE))
        })

        it("gas 대납", async function () {
          const [user, company, operator] = await ethers.getSigners()
          const cipherText = await user.signTransaction("")
          businessCard.connect(operator).permit(user.address, company.address, cipherText)
        })
      })
    })
