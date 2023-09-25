// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "../../src/EVaultFactory/EVaultFactory.sol";

contract MockEVault {
    constructor(address factory_, address cvc_) {
    }

    function initialize() external {
    }

    function implementation() external pure returns (string memory) {
        return "TRANSPARENT";
    }

    function UNPACK() internal pure returns (address marketAsset, address riskManager) {
        assembly {
            marketAsset := shr(96, calldataload(sub(calldatasize(), 40)))
            riskManager := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    function arbitraryFunction(string calldata arg) external view returns (string memory, address, address, address) {
        (address marketAsset, address riskManager) = UNPACK();
        return (arg, msg.sender, marketAsset, riskManager);
    }
}
