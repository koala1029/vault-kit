// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./types/Types.sol";

abstract contract Storage {
    bool initialized;

    MarketStorage marketStorage;

    struct UserStorage {
        PackedUserSlot data;

        uint256 interestAccumulator;
    }

    struct MarketSnapshot {
        // Packed slot 14 + 14 + 4 = 32
        Assets poolSize;
        Assets totalBorrows;
        uint32 performedOperations;
    }

    struct MarketStorage {
        // Packed slot 1 + 5 + 14 + 12 = 32
        uint8 reentrancyLock;
        uint40 lastInterestAccumulatorUpdate;
        Assets poolSize;
        Fees feesBalance;

        // Packed slot 14 + 18 = 32
        Shares totalShares;
        Owed totalBorrows;

        uint256 interestAccumulator;

        MarketSnapshot marketSnapshot;

        // Packed slot 9 + 2
        // Read on first item in a block (interest accrual). Read and written in vault status check DF(interest rate update).
        // Not touched on other batch items.
        uint72 interestRate;
        uint16 interestFee;

        mapping(address account => UserStorage) users;
        mapping(address owner => mapping(address spender => uint256 allowance)) eVaultAllowance;
    }
}
