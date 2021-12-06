// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7d17acfb2f12be0a2ad4c08ad4a3d823704b68d6/contracts/utils/math/SafeMath.sol";

contract ERC20Locker {

    IERC20 tok = IERC20(CONTRACT_ADDRESS_HERE);
    uint internal validUntil;
    uint internal totalRecords = 0;
    
    struct AmountValidityStruct {
        uint256 amount;
        uint256 validity;
        address payable addr;
        bool doesExist;
    }

    mapping(uint => AmountValidityStruct) public userLockRecords;

    constructor () {
        Ownable(msg.sender);
    }
    
    event Locked(
        address indexed _of,
        uint256 _amount,
        uint256 _validity
    );

    event Unlocked(
        address indexed _of,
        uint256 _amount
    );

    function lock (uint256 amount, uint timeInMinutes) public{
        require(amount > 0, "Amount should be greater than zero");
        require(address(msg.sender).balance >= amount, "Amount to be locked exceeds total balance!");
        uint timePerBlock = (timeInMinutes * 60) / 12;
        validUntil = block.number + timePerBlock;
        tok.transferFrom(msg.sender, address(this), amount);
        userLockRecords[totalRecords] = AmountValidityStruct(amount, validUntil, payable(msg.sender), true);
        ++totalRecords;
        emit Locked(msg.sender, amount, validUntil);
    }

    function unlock () public {
        uint i = 0;
        for (i; i < totalRecords; i++) {
            if (userLockRecords[i].addr == msg.sender) {
                if (userLockRecords[i].validity <= block.number) {
                    tok.transfer(msg.sender, userLockRecords[i].amount);
                    delete userLockRecords[i];
                    emit Unlocked(msg.sender, userLockRecords[i].amount);
                    break;
                }
            }
        }
        require(i < totalRecords, "There are no funds locked for the specified address");
    }

}