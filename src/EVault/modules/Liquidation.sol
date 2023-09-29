// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { ILiquidation } from "../IEVault.sol";

abstract contract LiquidationModule is ILiquidation {

}

contract Liquidation is LiquidationModule {}