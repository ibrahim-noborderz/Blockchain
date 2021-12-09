// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

contract Stakeable is Ownable, ReentrancyGuard {

    /*
        Variable Declaration Start
    */

    IERC20 EBToken = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);

    struct RewardPriceTrack {
        uint256 rewardPerBlock;
        uint256 fromBlock;
        uint256 toBlock;
    }

    RewardPriceTrack[] rewardPriceTrack;

    address[] internal stakeholders;

    mapping(address => uint256) internal userStakeAmount;

    mapping(address => uint256) internal userStakeBlock;

    /*
        Variable Declaration End
    */

    constructor (uint256 initialReward) {
        rewardPriceTrack.push(RewardPriceTrack(initialReward, block.number, 0));
    }

    /*
        Events Start
    */

    event Staked (address indexed stakeholder, uint256 amount, uint onBlockNumber, uint256 timestamp);

    event Unstaked (address indexed stakeholder, uint256 reward, uint256 timestamp);

    event Claimed (address indexed stakeholder, uint256 reward, uint256 timestamp);

    event TransferredFromUserToContract (address indexed user, uint256 amount, uint256 timestamp);

    event TransferredFromContractToUser (address indexed user, uint256 amount, uint256 timestamp);

    event InjectedRewardTokens (address indexed by, uint256 amount, uint256 timestamp);

    event RewardPerBlockUpdated (address indexed by, uint256 rewardValue, uint256 timestamp);

    /*
        Events End
    */

    /*
        Modifiers Start
    */

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

    /*
        Modifiers End
    */

    /*
        Helper Methods Start
    */

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function isStakeHolder () internal view returns (bool, uint) {
        uint index = 0;
        for (uint256 i = 0; i < stakeholders.length; i++) {
            index = i;
            if (stakeholders[i] == msg.sender) return (true, index);
        }
        return (false, index);
    }

    function removeStakeHolder () internal {
        (bool _isStakeHolder, uint256 index) = isStakeHolder();

        if (_isStakeHolder) {
            stakeholders[index] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    /*
        Helper Methods End
    */

    /*
        Admin Only Methods Start
    */

    function getLatestRewardPerBlock () onlyOwner public view returns (uint256) {
        return rewardPriceTrack[rewardPriceTrack.length - 1].rewardPerBlock;
    }

    function getRewardHistory () onlyOwner public view returns (RewardPriceTrack[] memory) {
        return rewardPriceTrack;
    }

    function setRewardPerBlock (uint256 rewardPerBlock) onlyOwner public {
        rewardPriceTrack[rewardPriceTrack.length - 1].toBlock = block.number - 1;
        rewardPriceTrack.push(RewardPriceTrack(rewardPerBlock, block.number, 0));
        emit RewardPerBlockUpdated(msg.sender, rewardPerBlock, block.timestamp);
    }

    function injetRewardToken (uint256 amountInEther) onlyOwner public {
        EBToken.transfer(address(EBToken), amountInEther * (10 ** 18));
        emit InjectedRewardTokens(msg.sender, amountInEther * (10 ** 18), block.timestamp);
    }

    /*
        Admin Only Methods End
    */

    /*
        Public Methods Start
    */

    function stake (address token, uint256 amount) public isAllowedToStake nonReentrant {
        require(isContract(token), "Provided address doesn't belong to a valid contract");
        require (amount > 0, "Cannot stake nothing");
        require (EBToken.balanceOf(msg.sender) > amount, "Insufficient balance! Stake amount exceeds current balance");

        userStakeAmount[msg.sender] += amount;
        userStakeBlock[msg.sender] = block.number;
        stakeholders.push(msg.sender);

        EBToken.transferFrom(payable(msg.sender), payable(address(this)), amount);
        emit TransferredFromUserToContract(msg.sender, amount, block.timestamp);
        emit Staked(msg.sender, amount, block.number, block.timestamp);
    }

    function claimReward () public isClaimable {
        // uint numberOfBlocks = (block.number - rewards[msg.sender]) > 0 ? (block.number - rewards[msg.sender]) : 1;
        // uint reward = (stakes[msg.sender] * numberOfBlocks) / rewardPerBlock;
        delete userStakeAmount[msg.sender];
        delete userStakeBlock[msg.sender];
        removeStakeHolder();
    }

    /*
        Public Methods End
    */

}