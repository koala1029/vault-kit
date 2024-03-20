// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./EVaultTestBase.t.sol";

import { console2 as console } from "forge-std/console2.sol";

contract DispatchTest is EVaultTestBase {
    function test_Dispatch_moduleGetters() public view {
        assertEq(eTST.MODULE_INITIALIZE(), initializeModule);
        assertEq(eTST.MODULE_TOKEN(), tokenModule);
        assertEq(eTST.MODULE_VAULT(), vaultModule);
        assertEq(eTST.MODULE_BORROWING(), borrowingModule);
        assertEq(eTST.MODULE_LIQUIDATION(), liquidationModule);
        assertEq(eTST.MODULE_RISKMANAGER(), riskManagerModule);
        assertEq(eTST.MODULE_BALANCE_FORWARDER(), balanceForwarderModule);
        assertEq(eTST.MODULE_GOVERNANCE(), governanceModule);
    }
}
