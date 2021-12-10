// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/*
    Imports for Remix
*/
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

/*
    Imports for local development
*/
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/Address.sol";

// Importing Reward Token Smart Contract
import "./EBToken.sol";

contract Stakeable is Ownable, ReentrancyGuard {

    /*
        Variable Declaration Start
    */

    // IERC20 EBToken = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
    EBToken internal rewardToken;

    struct RewardPriceTrack {
        uint256 rewardPerBlock;
        uint256 fromBlock;
        uint256 toBlock;
    }

    RewardPriceTrack[] internal rewardPriceTrack;

    address[] internal stakeholders;

    mapping(address => uint256) internal userStakeAmount;

    mapping(address => uint256) internal userStakeBlock;

    /*
        Variable Declaration End
    */

    constructor (uint256 initialReward) {
        rewardToken = new EBToken();
        rewardPriceTrack.push(RewardPriceTrack(initialReward, block.number, 0));
    }

    /*
        Events Start
    */

    event Staked (address indexed stakeholder, uint256 amount, uint onBlockNumber);

    event Unstaked (address indexed stakeholder, uint256 reward, uint256 blockNumber);

    event Claimed (address indexed stakeholder, uint256 reward, uint256 blockNumber);

    event TransferredFromUserToContract (address indexed user, uint256 amount, uint256 blockNumber);

    event TransferredFromContractToUser (address indexed user, uint256 amount, uint256 blockNumber);

    event InjectedRewardTokens (address indexed by, uint256 amount, uint256 blockNumber);

    event RewardPerBlockUpdated (address indexed by, uint256 rewardValue, uint256 blockNumber);

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

    function calculateUserReward (address user) internal view returns (uint256) {
        /*
            1) Get block number when user staked from 'userStakeBlock'
            2) Check if latest value of 'fromBlock' is equal to current block.number;
            // if so, latest 'rewardPerBlock' value shall apply to (block.number - userStakeBlock)
            3) Else, get index where 'userStakeBlock' equals 'fromBlock' in 'rewardPriceTrack'
            4) Start looping from index found in 3) reward shall be the sum of (toBlock - fromBlock) * rewardPerBlock
            // and for index == rewardPriceTrack.length-1 value to add will be ( (block.number - fromBlock) * rewardPerBlock)
            // if block.number - fromBlock equals zero then rewardPerBlock shall be added to total reward calculated. 
        */
        uint256 userBlock = userStakeBlock[user];
        uint256 latestRewardBlock = rewardPriceTrack[rewardPriceTrack.length - 1].fromBlock;
        if (userBlock == block.number) return rewardPriceTrack[rewardPriceTrack.length - 1].rewardPerBlock * userStakeAmount[user];
        else if (latestRewardBlock == block.number || userBlock > latestRewardBlock) {
            return ((block.number - userBlock) * rewardPriceTrack[rewardPriceTrack.length - 1].rewardPerBlock) * userStakeAmount[user];
        } else {
            uint256 reward = 0;
            uint rewardStartIndex = getRewardStartIndex(userBlock);
            for (rewardStartIndex; rewardStartIndex < rewardPriceTrack.length - 1; rewardStartIndex++) {
                reward += ((rewardPriceTrack[rewardStartIndex].toBlock - rewardPriceTrack[rewardStartIndex].fromBlock) * rewardPriceTrack[rewardStartIndex].rewardPerBlock) * userStakeAmount[user];
            }
            return reward;
        }
    }

    function getRewardStartIndex (uint userBlock) internal view returns (uint) {
        for (uint i = 0; i < rewardPriceTrack.length - 2; i++) {
            if (rewardPriceTrack[i].fromBlock <= userBlock && rewardPriceTrack[i].toBlock >= userBlock) {
                return i;
            }
        }
        return 0;
    }

    /*
        Helper Methods End
    */

    /*
        Admin Only Methods Start
    */

    function getLatestRewardPerBlock () public onlyOwner view returns (uint256) {
        return rewardPriceTrack[rewardPriceTrack.length - 1].rewardPerBlock;
    }

    function getRewardHistory () public onlyOwner view returns (RewardPriceTrack[] memory) {
        return rewardPriceTrack;
    }

    function setRewardPerBlock (uint256 rewardPerBlock) public onlyOwner {
        rewardPriceTrack[rewardPriceTrack.length - 1].toBlock = block.number - 1;
        rewardPriceTrack.push(RewardPriceTrack(rewardPerBlock, block.number, 0));
        emit RewardPerBlockUpdated(msg.sender, rewardPerBlock, block.number);
    }

    function injetRewardToken (uint256 amountInEther) public onlyOwner {
        rewardToken.mintAmountAsEther(amountInEther);
        emit InjectedRewardTokens(msg.sender, amountInEther * (10 ** 18), block.number);
    }

    /*
        Admin Only Methods End
    */

    /*
        Public Methods Start
    */

    function stake (address tokenAddress, uint256 amountInWei) payable public isAllowedToStake nonReentrant {
        require(isContract(tokenAddress), "Provided address doesn't belong to a valid contract");
        require (amountInWei > 0, "Cannot stake nothing");
        IERC20 userToken = IERC20(tokenAddress);
        // Checking user balance
        require (userToken.balanceOf(msg.sender) > amountInWei, "Insufficient balance! Stake amount exceeds current balance");
        // Processing payment
        require(userToken.transferFrom(msg.sender, address(this), amountInWei), "Payment failed!!! Please make sure you've approved amount you want to stake and try again.");
        emit TransferredFromUserToContract(msg.sender, amountInWei, block.number);

        userStakeAmount[msg.sender] = amountInWei;
        userStakeBlock[msg.sender] = block.number;
        stakeholders.push(msg.sender);
        emit Staked(msg.sender, amountInWei, block.number);
    }

    function claimReward () payable public isClaimable nonReentrant {
        uint256 reward = calculateUserReward(msg.sender);
        // Minting number of reward tokens to be transferred to staker
        rewardToken.mintAmountAsWEI(reward);
        emit InjectedRewardTokens(msg.sender, reward, block.number);
        // Approving reward tokens for staker
        rewardToken.approve(msg.sender, reward);
        // Transferring reward to staker
        rewardToken.transfer(msg.sender, reward);
        emit TransferredFromContractToUser(msg.sender, reward, block.number);
        // Removing Staker's data
        delete userStakeAmount[msg.sender];
        delete userStakeBlock[msg.sender];
        removeStakeHolder();
        emit Claimed(msg.sender, reward, block.number);
    }

    /*
        Public Methods End
    */

}