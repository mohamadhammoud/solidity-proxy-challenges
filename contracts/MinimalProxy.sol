// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MinimalProxyFactory {
    using Clones for address;
    address public implementation;

    event NewContract(address indexed);

    constructor(address implementation_) {
        implementation = implementation_;
    }

    function clone() external returns (address) {
        address newContract = implementation.clone();

        emit NewContract(newContract);

        return newContract;
    }
}

contract StoreMinimal {
    address owner;
    uint256 value;

    function setValue(uint256 newValue) external {
        owner = msg.sender;
        value = newValue;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
