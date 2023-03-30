const { messagePrefix } = require("@ethersproject/hash")
const { assert, expect } = require("chai")
const { ethers, deployments, getNamedAccounts } = require("hardhat")

developmentChains = ["hardhat", "localhost"]
FIRST_MINT_PRICE = ethers.utils.parseEther("1")
MINT_PRICE = ethers.utils.parseEther("0.2")
STAKE_PRICE = ethers.utils.parseEther("2")
DESIRED_VALUE = ethers.utils.parseEther("0.3")

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("BusinessCardTesting", () => {
      let deployer
      beforeEach(async () => {
        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        thirdParty = accounts[1]
        company = accounts[2]
        await deployments.fixture(["all"])
        businessCardBase = await ethers.getContract("BusinessCardBase")
        await businessCardBase.__BusinessCardBase__init(FIRST_MINT_PRICE, MINT_PRICE, STAKE_PRICE)
      })

      describe("constructor", () => {
        it("initializes first mint price /  mint price properly", async () => {
          const firstMintPrice = await businessCardBase.getFirstMintPrice()
          const mintPrice = await businessCardBase.getMintPrice()
          assert.equal(Number(firstMintPrice), Number(FIRST_MINT_PRICE))
          assert.equal(Number(mintPrice), Number(MINT_PRICE))
        })

        // it("gas 대납", async function () {
        //   const [user, company, operator] = await ethers.getSigners()
        //   const cipherText = await user.signTransaction("")
        //   businessCardBase.connect(operator).permit(user.address, company.address, cipherText)
        // })
      })

      describe("mint", () => {
        beforeEach(async () => {
          await businessCardBase.mint({ value: FIRST_MINT_PRICE })
        })
        it("reverts if paid less than 1 eth during first mint", async () => {
          await expect(businessCardBase.connect(thirdParty).mint({ value: ethers.utils.parseEther("0.99") })).to.be.revertedWith(
            "BusinessCardBase__InvalidETHAmountSent"
          )
        })
        it("earns 10 mintable authorities when 1 eth paid and firstMinted set true", async () => {
          const mintableAuthorities = await businessCardBase.getMintableAuthorities(deployer.address, deployer.address)
          assert.equal(Number(mintableAuthorities), 10)
          assert.equal(await businessCardBase.getFirstMinted(deployer.address), true)
        })
        it("earns 11 mintable authorities additional 0.2 eth paid subsequently", async () => {
          await businessCardBase.mint({ value: MINT_PRICE })
          const mintableAuthorities = await businessCardBase.getMintableAuthorities(deployer.address, deployer.address)
          assert.equal(Number(mintableAuthorities), 11)
        })
        // what if paid 0.3 eth paid?
      })

      describe("_mint", () => {
        beforeEach(async () => {
          // PERSONAL CARD MINT
          await businessCardBase.mint({ value: FIRST_MINT_PRICE })
        })
        it("reverts if no mintable authorities", async () => {
          await expect(
            businessCardBase.connect(thirdParty)._mint("a", "a@gmail.com", "01012341234", thirdParty.address, DESIRED_VALUE)
          ).to.be.revertedWith("BusinessCardBase__NotMintable")
        })
        it("reverts if has null input values", async () => {
          const mintableAuthorities = await businessCardBase.getMintableAuthorities(deployer.address, deployer.address)
          assert(mintableAuthorities > 0)
          await expect(businessCardBase._mint("", "a@gmail.com", "01012341234", thirdParty.address, DESIRED_VALUE)).to.be.revertedWith(
            "BusinessCardBase__InvalidString"
          )
          await expect(businessCardBase._mint("a", "", "01012341234", thirdParty.address, DESIRED_VALUE)).to.be.revertedWith(
            "BusinessCardBase__InvalidString"
          )
          await expect(businessCardBase._mint("a", "a@gmail.com", "", thirdParty.address, DESIRED_VALUE)).to.be.revertedWith(
            "BusinessCardBase__InvalidString"
          )
          await expect(businessCardBase._mint("a", "a@gmail.com", "01012341234", ethers.constants.AddressZero, DESIRED_VALUE)).to.be.revertedWith(
            "BusinessCardBase__InvalidString"
          )
          await expect(businessCardBase._mint("a", "a@gmail.com", "01012341234", thirdParty.address, 0)).to.be.revertedWith(
            "BusinessCardBase__InvalidString"
          )
        })
        it("successfully determines the cardType in case of personal", async () => {
          const tx = await businessCardBase._mint("a", "a@gmail.com", "01012341234", deployer.address, DESIRED_VALUE)
          const txr = await tx.wait(1)
          cardType = await businessCardBase.getCardByOwner(deployer.address, 0)
          assert.equal(cardType[4], 0)
        })
        it("successfully emits CardCreated event", async () => {
          const tx = await businessCardBase._mint("a", "a@gmail.com", "01012341234", deployer.address, DESIRED_VALUE)
          const txr = await tx.wait(1)
          const cardCreatedEvent = txr.events[1]
          assert.equal(cardCreatedEvent.args[3], "01012341234")
        })
        it("subtracts from total mintable authorities", async () => {
          businessCardBaseThirdPartyConnected = businessCardBase.connect(thirdParty)
          businessCardBaseThirdPartyConnected.mint({ value: FIRST_MINT_PRICE })
          const mintableAuthoritiesBefore = await businessCardBase.getMintableAuthorities(thirdParty.address, thirdParty.address)
          await businessCardBaseThirdPartyConnected._mint("a", "a@gmail.com", "01012341234", deployer.address, DESIRED_VALUE)
          const mintableAuthoritiesAfter = await businessCardBase.getMintableAuthorities(thirdParty.address, thirdParty.address)
          expect(mintableAuthoritiesBefore > mintableAuthoritiesAfter)
        })
      })

      describe("stake", () => {
        beforeEach(async () => {
          await businessCardBase.stake({ value: STAKE_PRICE })
        })
        it("reverts if paid less than 0.2 eth", async () => {
          await expect(businessCardBase.connect(thirdParty).stake({ value: ethers.utils.parseEther("0.19") })).to.be.revertedWith(
            "BusinessCardBase__InvalidETHAmountSent"
          )
        })
      })
    })
