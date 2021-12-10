// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/*
    Imports for Remix
*/
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/*
    Imports for Remix
*/
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract EBToken is ERC20, Ownable {

    constructor () ERC20("EB Token", "EBT") {
        _mint(address(this), 1000000 * (10 ** 18));
    }

    function mintAmountAsEther (uint256 amount) onlyOwner public {
        _mint(address(this), amount * (10 ** 18));
    }

    function mintAmountAsWEI (uint256 amount) onlyOwner public {
        _mint(address(this), amount);
    }

    // function decimals () public view virtual override returns (uint8) {
    //     return 2;
    // }

}