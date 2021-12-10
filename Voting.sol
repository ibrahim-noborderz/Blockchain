// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/*
    Imports
*/
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract Voting is Ownable, ReentrancyGuard {

    /*
        Variable Declaration Start
    */
    struct Voter {
        address _address;
        uint256 isInFavor;
        uint256 balance;
    }

    Voter[] private voters;
    address private _owner;

    uint256 private votingStartTime = 0;
    uint256 private votingEndTime = 0;
    uint256 private votesInFavor = 0;
    uint256 private votesAgainst = 0;
    /*
        Variable Declaration End
    */

    constructor () {
        _owner = msg.sender;
    }

    /*
        Events Start
    */
    event Voting_Started (address by, uint256 time);
    event Voting_Ended (address by, uint256 total_votes ,uint256 time);
    event Vote_Casted (address voter, uint256 decision, uint256 time);
    event Voting_Reset (address by, uint256 time);
    event Get_Voters (Voter[] voters);
    event Get_Total_Votes (address viewer, uint256 votes, uint256 time);
    event Get_Total_Voters (address viewer, uint256 voters, uint256 time);
    event Get_Votes_In_Favor (uint256 votes_in_favor);
    event Get_Votes_Against (uint256 votes_against);
    /*
        Events End
    */

    /*
        Modifiers Start
    */
    modifier validateVoter () {
        // Prevent owner from voting himself 
        require (msg.sender != _owner, "Owner cannot cast votes!");
        
        bool isVoterValid = true;

        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i]._address == msg.sender) {
                isVoterValid = false;
                break;
            }
        }

        require(isVoterValid, "A user can only vote once!");
        _;
    }

    modifier votingStarted () {
        require (votingStartTime != 0, "Voting has not started yet!");
        _;
    }

    modifier votingEnded () {
        require(votingEndTime != 0 && votingStartTime <= block.timestamp 
        && block.timestamp >= votingEndTime, "Voting has not ended yet!");
        _;
    }

    modifier validateVoting () {
        require (block.timestamp <= votingEndTime, "Voting has ended!");
        _;
    }
    /*
        Modifiers End
    */

    /*
        Admin methods start
    */

    function calculateResults () private {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].isInFavor == 1) {
                votesInFavor += voters[i].balance;
            } else {
                votesAgainst += voters[i].balance;
            }
        }
    }

    function startVoting () public onlyOwner {
        require(votingStartTime == 0, "Voting has already started");
        votingStartTime = block.timestamp;
        emit Voting_Started(msg.sender, block.timestamp);
    }

    function endVoting () public onlyOwner votingStarted {
        votingEndTime = block.timestamp;
        calculateResults();
        emit Voting_Ended(msg.sender, votesInFavor + votesAgainst, block.timestamp);
    }

    function reset () public onlyOwner votingEnded {
        votingStartTime = 0;
        votingEndTime = 0;
        delete voters;
        emit Voting_Reset(msg.sender, block.timestamp);
    }

    function ShowVotersWithResults () public onlyOwner votingEnded returns (Voter[] memory) {
        emit Get_Voters(voters);
        return voters;
    }
    /*
        Admin methods end
    */

    /*
        User/Public methods start
    */

    function Vote (uint256 _vote) public votingStarted validateVoter validateVoting {
        // Validating input
        require (_vote >= 0 && _vote <= 1,
        "Please enter either 0 for No or 1 for Yes ");
        voters.push(Voter(msg.sender, _vote, (msg.sender).balance));
        emit Vote_Casted(msg.sender, _vote, block.timestamp);
    }

    function TotalVoters () public votingEnded returns (uint256) {
        emit Get_Total_Voters(msg.sender, voters.length, block.timestamp);
        return voters.length;
    }

    function TotalVotes () public votingEnded returns (uint256) {
        uint256 totalVotes = votesInFavor + votesAgainst;
        emit Get_Total_Votes(msg.sender, totalVotes, block.timestamp);
        return totalVotes;
    }

    function VotesInFavor () public votingEnded returns (uint256) {
        emit Get_Votes_In_Favor(votesInFavor);
        return votesInFavor;
    }

    function VotesAgainst () public votingEnded returns (uint256) {
        emit Get_Votes_Against(votesAgainst);
        return votesAgainst;
    }

    function GetVotingResults () public view returns (string memory) {
        if (votesInFavor > votesAgainst) {
            return "Majority is in Favor, Candidate WON!!!";
        } else if (votesInFavor < votesAgainst) {
            return "Majority is in Favor, Candidate LOST!!!";
        } else {
            return "Equal worth of votes on both sides, It's a DRAW!!!";
        }
    }

    /*
        User/Public methods end
    */

}