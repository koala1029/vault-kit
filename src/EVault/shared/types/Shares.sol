// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {Shares, Assets, TypesLib} from "./Types.sol";
import {MarketCache} from "./MarketCache.sol";
import "./ConversionHelpers.sol";

library SharesLib {
    function toUint(Shares self) internal pure returns (uint256) {
        return Shares.unwrap(self);
    }

    function isZero(Shares self) internal pure returns (bool) {
        return Shares.unwrap(self) == 0;
    }

    function toAssetsDown(Shares amount, MarketCache memory marketCache) internal pure returns (Assets) {
        (uint256 totalAssets, uint256 totalShares) = conversionTotals(marketCache);
        unchecked {
            return TypesLib.toAssets(amount.toUint() * totalAssets / totalShares);
        }
    }

    function toAssetsUp(Shares amount, MarketCache memory marketCache) internal pure returns (Assets) {
        (uint256 totalAssets, uint256 totalShares) = conversionTotals(marketCache);
        unchecked {
            return TypesLib.toAssets((amount.toUint() * totalAssets + (totalShares - 1)) / totalShares);
        }
    }

    function mulDiv(Shares self, uint256 multiplier, uint256 divisor) internal pure returns (Shares) {
        return TypesLib.toShares(uint256(Shares.unwrap(self)) * multiplier / divisor);
    }
}

function addShares(Shares a, Shares b) pure returns (Shares) {
    return TypesLib.toShares(uint256(Shares.unwrap(a)) + uint256(Shares.unwrap(b)));
}

function subShares(Shares a, Shares b) pure returns (Shares) {
    return Shares.wrap((Shares.unwrap(a) - Shares.unwrap(b)));
}

function eqShares(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) == Shares.unwrap(b);
}

function neqShares(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) != Shares.unwrap(b);
}

function gtShares(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) > Shares.unwrap(b);
}

function ltShares(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) < Shares.unwrap(b);
}
