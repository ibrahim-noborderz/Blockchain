// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingToken is Ownable {

    uint256 internal rewardPerBlock = 100;

    address[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    mapping(address => uint256) internal rewards;

    constructor () {}

    event Staked (address indexed stakeholder, uint256 amount, uint onBlockNumber, uint256 timestamp);

    event Unstaked (address indexed stakeholder, uint256 reward, uint256 timestamp);

    event Claimed (address indexed stakeholder, uint256 reward, uint256 timestamp);

    event TransferredFromUserToContract (address indexed user, uint256 amount, uint256 timestamp);

    event TransferredFromContractToUser (address indexed user, uint256 amount, uint256 timestamp);

    event InjectedRewardTokens (address indexed by, uint256 amount, uint256 timestamp);

    event RewardPerBlockUpdated (address indexed by, uint256 rewardValue, uint256 timestamp);

    modifier isAllowedToStake () {
        (bool _isStakeHolder, ) = isStakeHolder();
        require(!_isStakeHolder, "You've currently staked some assets, please claim/withdraw to stake again.");
        _;
    }

    modifier isClaimable () {
        (bool _isStakeHolder, ) = isStakeHolder();
        require(_isStakeHolder, "You've nothing to claim!!!");
        _;
    }

    function isStakeHolder () internal view returns (bool, uint) {
        uint index = 0;
        for (uint256 i = 0; i < stakeholders.length; i++) {
            index = i;
            if (stakeholders[i] == msg.sender) return (true, index);
        }
        return (false, index);
    }

    function getRewardPerBlock () onlyOwner public view returns (uint256){
        return rewardPerBlock;
    }

    function setRewardPerBlock (uint256 reward) onlyOwner public {
        rewardPerBlock = reward;
    }

    function injetRewardToken (uint256 amountInEther) onlyOwner public {
        //_mint(msg.sender, amountInEther * (10 ** 18));


    }

    function stake (uint256 amount) public isAllowedToStake {
        require (amount > 0, "Cannot stake nothing");

        stakes[msg.sender] += amount;
        rewards[msg.sender] = block.number;
        stakeholders.push(msg.sender);

        // _burn(msg.sender, amount);
        emit Staked(msg.sender, amount, block.number, block.timestamp);
    }

    function claimReward () public isClaimable {
        uint numberOfBlocks = (block.number - rewards[msg.sender]) > 0 ? (block.number - rewards[msg.sender]) : 1;
        uint reward = (stakes[msg.sender] * numberOfBlocks) / rewardPerBlock;
        delete stakes[msg.sender];
        delete rewards[msg.sender];
        removeStakeHolder();

    }

    function removeStakeHolder () internal {
        (bool _isStakeHolder, uint256 index) = isStakeHolder();

        if (_isStakeHolder) {
            stakeholders[index] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }


}