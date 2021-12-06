// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Voting {

    struct Voter {
        address _address;
        bool isInFavor;
        uint balance;
    }

    Voter[] private voters;
    address private owner;

    constructor () {
        owner = msg.sender;
    }

    modifier validateVoter () {
        require (msg.sender != owner, "Owner cannot cast votes!");
        
        bool isVoterValid = true;

        for (uint i = 0; i < voters.length; i++) {
            if (voters[i]._address == msg.sender) {
                isVoterValid = false;
                break;
            }
        }

        require(isVoterValid, "A user can only vote once!");
        _;
    }

    function VoteInFavor () public validateVoter {
        voters.push( Voter(msg.sender, true, (msg.sender).balance) );
    }

    function VoteAgainst () public validateVoter {
        voters.push( Voter(msg.sender, false, (msg.sender).balance) );
    }

    function TotalVotesCasted () public view returns (uint totalVotes){
        totalVotes = voters.length;
    }

    function GetResult () public view returns (string memory) {
        uint coinsInFavor = 0;
        uint coinsAgainst = 0;
        
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i].isInFavor) {
                coinsInFavor += voters[i].balance;
            } else {
                coinsAgainst += voters[i].balance;
            }
        }

        if (coinsInFavor > coinsAgainst) {
            return "Majority is in Favor, Candidate WON!!!";
        } else if (coinsInFavor < coinsAgainst) {
            return "Majority is in Favor, Candidate LOST!!!";
        } else {
            return "Equal worth of votes on both sides, It's a DRAW!!!";
        }
    }

}