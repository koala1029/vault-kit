// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC20} from "../../IEVault.sol";
import {IRiskManager} from "../../../IRiskManager.sol";

import "./Types.sol";

struct MarketCache {
    IERC20 asset;
    IRiskManager riskManager;
    Shares totalShares;
    Owed totalBorrows;
    uint40 lastInterestAccumulatorUpdate;
    Assets poolSize;
    Fees feesBalance;
    uint256 interestAccumulator;
}
