// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./IIRM.sol";

contract BaseIRMLinearKink is IIRM {
    uint256 public immutable baseRate;
    uint256 public immutable slope1;
    uint256 public immutable slope2;
    uint256 public immutable kink;

    constructor(uint256 baseRate_, uint256 slope1_, uint256 slope2_, uint256 kink_) {
        baseRate = baseRate_;
        slope1 = slope1_;
        slope2 = slope2_;
        kink = kink_;
    }

    function computeInterestRate(address, uint256 cash, uint256 borrows) external view override returns (uint256) {
        uint256 ir = baseRate;

        uint256 totalAssets = cash + borrows;

        uint32 utilisation = totalAssets == 0
           ? 0 // empty pool arbitrarily given utilisation of 0
           : uint32(borrows * type(uint32).max / totalAssets);

        if (utilisation <= kink) {
            ir += utilisation * slope1;
        } else {
            ir += kink * slope1;
            ir += slope2 * (utilisation - kink);
        }

        return uint256(ir);
    }
}
