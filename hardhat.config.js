require("@nomicfoundation/hardhat-toolbox");
require("hardhat-tracer");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.15",
            },
        ],
        overrides: {
            "contracts/NameServiceBank.sol": {
                version: "0.7.0",
            },
            "contracts/solutions/NameServiceAttacker.sol": {
                version: "0.7.0",
            },
        },
    },
    networks: {
        mainnet: {
            url: "https://mainnet.infura.io/v3/f64a1f26acf7432287e2283e33714ca3",
        }
    },
    paths: {
        sources: "./contracts",
    },
};
