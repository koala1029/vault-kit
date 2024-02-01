// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Types.sol";
import "./MarketCache.sol";
import "./Helpers.sol";

import "hardhat/console.sol";

library SharesLib {
    function toUint(Shares self) internal pure returns (uint256) {
        return Shares.unwrap(self);
    }

    function isZero(Shares self) internal pure returns (bool) {
        return Shares.unwrap(self) == 0;
    }

    function toAssetsDown(Shares amount, MarketCache memory marketCache) internal pure returns (Assets) {
        (uint256 totalAssets, uint256 totalShares) = totals(marketCache);
        unchecked {
            return TypesLib.toAssets(amount.toUint() * totalAssets / totalShares);
        }
    }

    function toAssetsUp(Shares amount, MarketCache memory marketCache) internal pure returns (Assets) {
        (uint256 totalAssets, uint256 totalShares) = totals(marketCache);
        unchecked {
            return TypesLib.toAssets((amount.toUint() * totalAssets + (totalShares - 1)) / totalShares);
        }
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
